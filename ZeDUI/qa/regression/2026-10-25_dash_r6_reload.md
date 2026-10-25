# ZeD-UI regression - 2026-10-25 00:16 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 00:16:19 |
| Finished | 2026-10-25 00:22:17 (5 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/dash_r6_reload.txt (3 scripts) |
| Result | **2/3 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 12409 to 12413 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 12412, 12413)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dash_r6_persist.lua | r6r | **FAIL** | 8 | zqa_r6r_site.png | 22 Java exception(s) in the log; 2 ERR line(s) |
| 3 | zedqa_dash_r6_parts.lua | r6p | PASS | 241 | zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_fossoil.png, zqa_r6p_van_mccoy.png, zqa_r6p_van_johnmccoy.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_mail.png, zqa_r6p_van_plain.png, zqa_r6p_van_plain_open.png, zqa_r6p_van_creature.png, zqa_r6p_van_creature_shut.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_flag_up.png, zqa_r6p_taxi_flag_down.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_hula1.png, zqa_r6p_taxi_hula2.png, zqa_r6p_taxi_stopped.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_taxi_keyout.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 12409 at 00:17:28

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre DONE
```

### 2. zedqa_dash_r6_persist.lua (`ZEDQA r6r`) - FAIL, 8 s

- go 12410 at 00:17:33
- 22 Java exception(s) in the log
- 2 ERR line(s)
- screenshots: zqa_r6r_site.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ERROR: General f:981 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:997 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6r at the speedway 925,13040 (home 10985,11301)
ZEDQA r6r ERR untouched car with key 81630613 not found after the reload
ZEDQA r6r ERR clicked car with key 25304096 not found after the reload
    Lua fail. Message: Tried to call nil
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    se.krka.kahlua.vm.KahluaUtil.luaAssert(KahluaUtil.java:90)
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:842)
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
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:279)
    zombie.gameStates.IngameState.onTick(IngameState.java:1657)
    zombie.gameStates.IngameState.updateInternal(IngameState.java:1573)
    zombie.gameStates.IngameState.update(IngameState.java:1370)
    zombie.gameStates.GameStateMachine.update(GameStateMachine.java:65)
    zombie.GameWindow.logic(GameWindow.java:391)
    zombie.GameWindow.frameStep(GameWindow.java:791)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1307> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ZEDQA r6r back home 10985,11301
    Lua fail. Message: Tried to call nil
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    se.krka.kahlua.vm.KahluaUtil.luaAssert(KahluaUtil.java:90)
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:842)
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
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:279)
    zombie.gameStates.IngameState.onTick(IngameState.java:1657)
    zombie.gameStates.IngameState.updateInternal(IngameState.java:1573)
    zombie.gameStates.IngameState.update(IngameState.java:1370)
    zombie.gameStates.GameStateMachine.update(GameStateMachine.java:65)
    zombie.GameWindow.logic(GameWindow.java:391)
    zombie.GameWindow.frameStep(GameWindow.java:791)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:1340> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ERROR: General f:1340> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:122)
    Lua(Vanilla).act(spawnpoints.lua:122)
    Lua(Vanilla).step(spawnpoints.lua:16)
    Lua(Vanilla).tick(spawnpoints.lua:147)
ZEDQA r6r errors=2
ZEDQA r6r DONE
```

### 3. zedqa_dash_r6_parts.lua (`ZEDQA r6p`) - PASS, 241 s

- go 12411 at 00:17:45
- screenshots: zqa_r6p_site.png, zqa_r6p_van_spiffo.png, zqa_r6p_van_fossoil.png, zqa_r6p_van_mccoy.png, zqa_r6p_van_johnmccoy.png, zqa_r6p_van_mechanic.png, zqa_r6p_van_mail.png, zqa_r6p_van_plain.png, zqa_r6p_van_plain_open.png, zqa_r6p_van_creature.png, zqa_r6p_van_creature_shut.png, zqa_r6p_van_stepvan.png, zqa_r6p_van_stepvan_open.png, zqa_r6p_taxi_flag_up.png, zqa_r6p_taxi_flag_down.png, zqa_r6p_taxi_extras.png, zqa_r6p_taxi_waited.png, zqa_r6p_taxi_hula1.png, zqa_r6p_taxi_hula2.png, zqa_r6p_taxi_stopped.png, zqa_r6p_taxi_night_lit.png, zqa_r6p_taxi_night_dark.png, zqa_r6p_taxi_keyout.png, zqa_r6p_night_van_lit.png, zqa_r6p_night_van_dark.png, zqa_r6p_night_ambulance_lit.png, zqa_r6p_night_ambulance_dark.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ERROR: General f:1678 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:1687 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6p at the speedway 925,13040 (home 10985,11301)
ZEDQA r6p van_spiffo design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_SpiffosDECAL.png ash=false/0
ZEDQA r6p van_fossoil design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_FossoilDECAL.png ash=false/0
ZEDQA r6p van_mccoy design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_McCoysDECAL.png ash=false/0
ZEDQA r6p van_johnmccoy design=van vanRight=nil vanTray=false logo=media/textures/shirtdecals/Buisness_McCoysDECAL.png ash=false/0
ZEDQA r6p van_mechanic design=van vanRight=nosmoke vanTray=false logo=none ash=false/0
ZEDQA r6p van_mail design=van vanRight=nosmoke vanTray=false logo=none ash=false/0
ZEDQA r6p van_plain design=van vanRight=ash vanTray=true logo=none ash=false/0
ZEDQA r6p van_plain tray clicked: open false -> true level=3
ZEDQA r6p van_creature design=van vanRight=ash vanTray=true logo=none ash=true/1
ZEDQA r6p van_creature tray clicked: open true -> false level=0
ZEDQA r6p van_stepvan design=van vanRight=ash vanTray=true logo=none ash=false/0
ZEDQA r6p van_stepvan tray clicked: open false -> true level=2
ZEDQA r6p taxi sandbox ZeD: true flag=1.5 fifth=0.25 minute=0.25 extra=0.5
ZEDQA r6p taxi key in, engine off: meter hit enabled=true meterOn=false
ZEDQA r6p taxi running: unit="TAXI - CAB 65" hula=0 meterOn=false fare=0.00 rect=1120,1804,1600,344 k=2
ZEDQA r6p taxi flag down: meterOn=true fare=1.50 extras=0.00 riders(real)=driver only
ZEDQA r6p taxi sandbox flag drop 2.00 -> fare 2.00
ZEDQA r6p taxi riders 2 -> extras 0.50
ZEDQA r6p taxi riders 3 -> extras 1.00
ZEDQA r6p taxi riders 1 -> extras 0.00
ZEDQA r6p taxi waiting from fare 1.50
ZEDQA r6p taxi waited 30 s: fare 1.50
ZEDQA r6p taxi waited 61 s: fare 1.75
ZEDQA r6p taxi QA seed: the meter's distance set to 0.19 mi, fare 1.75
ZEDQA r6p taxi drive left t=1 push=100 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=64s heading=nil
ZEDQA r6p taxi drive left t=2 push=200 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=65s heading=nil
ZEDQA r6p taxi drive left t=3 push=400 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=66s heading=nil
ZEDQA r6p taxi drive left t=4 push=800 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=67s heading=nil
ZEDQA r6p taxi drive left t=5 push=1600 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=68s heading=nil
ZEDQA r6p taxi drive left t=6 push=3200 fwd=0.01,0.01,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=69s heading=nil
ZEDQA r6p taxi drive left t=7 push=6400 fwd=0.01,0.00,-1.00 kmh=1.4 yaw=0.00 hula=0 fare=1.75 miles=0.190 wait=70s heading=-1.5707963267948966
ZEDQA r6p taxi drive left t=9 push=6400 fwd=0.01,0.00,-1.00 kmh=6.3 yaw=0.48 hula=1 fare=1.75 miles=0.191 wait=71s heading=-1.4994888620096063
ZEDQA r6p taxi drive left t=10 push=6400 fwd=0.01,0.00,-1.00 kmh=15.0 yaw=0.33 hula=1 fare=1.75 miles=0.193 wait=71s heading=-1.5208379310729538
ZEDQA r6p taxi drive left t=11 push=6400 fwd=0.01,0.00,-1.00 kmh=22.4 yaw=-0.10 hula=0 fare=1.75 miles=0.196 wait=71s heading=-1.5707963267948966
ZEDQA r6p taxi drive left t=12 push=6400 fwd=0.00,0.00,-1.00 kmh=25.1 yaw=0.17 hula=0 fare=2.00 miles=0.200 wait=71s heading=-1.5430256902014756
ZEDQA r6p taxi drive left t=13 push=6400 fwd=-0.01,0.00,-1.00 kmh=25.0 yaw=0.05 hula=0 fare=2.00 miles=0.205 wait=71s heading=-1.5707963267948966
ZEDQA r6p taxi drive left t=14 push=6400 fwd=-0.01,0.00,-1.00 kmh=25.1 yaw=0.03 hula=0 fare=2.00 miles=0.206 wait=71s heading=-1.5707963267948966
ERROR: General f:17928 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA r6p taxi drive left t=15 push=12800 fwd=-0.05,0.05,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=71s heading=0
ZEDQA r6p taxi drive left t=16 push=25600 fwd=-0.07,0.06,-1.00 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=72s heading=nil
ZEDQA r6p taxi drive left t=17 push=50000 fwd=-0.10,0.06,-0.99 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=73s heading=nil
ZEDQA r6p taxi drive left t=18 push=50000 fwd=-0.15,0.07,-0.99 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=74s heading=nil
ZEDQA r6p taxi drive left t=19 push=50000 fwd=-0.18,0.08,-0.98 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=75s heading=nil
ZEDQA r6p taxi drive left t=20 push=50000 fwd=-0.21,0.09,-0.97 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=76s heading=nil
ZEDQA r6p taxi drive left t=21 push=50000 fwd=-0.22,0.10,-0.97 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=77s heading=nil
ZEDQA r6p taxi drive left t=22 push=50000 fwd=-0.23,0.12,-0.97 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=78s heading=nil
ZEDQA r6p taxi drive left t=23 push=50000 fwd=-0.24,0.14,-0.96 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=79s heading=nil
ZEDQA r6p taxi drive left t=24 push=50000 fwd=-0.24,0.15,-0.96 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=80s heading=nil
ZEDQA r6p taxi drive right t=1 push=50000 fwd=-0.25,0.18,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=81s heading=nil
ZEDQA r6p taxi drive right t=2 push=50000 fwd=-0.25,0.19,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=82s heading=nil
ZEDQA r6p taxi drive right t=3 push=50000 fwd=-0.25,0.20,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=83s heading=nil
ZEDQA r6p taxi drive right t=4 push=50000 fwd=-0.25,0.20,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=84s heading=nil
ZEDQA r6p taxi drive right t=5 push=50000 fwd=-0.25,0.21,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=85s heading=nil
ZEDQA r6p taxi drive right t=6 push=50000 fwd=-0.25,0.21,-0.95 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=86s heading=nil
ZEDQA r6p taxi drive right t=7 push=50000 fwd=-0.25,0.22,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=87s heading=nil
ZEDQA r6p taxi drive right t=8 push=50000 fwd=-0.25,0.22,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=88s heading=nil
ZEDQA r6p taxi drive right t=9 push=50000 fwd=-0.25,0.23,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=89s heading=nil
ZEDQA r6p taxi drive right t=10 push=50000 fwd=-0.25,0.24,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=90s heading=nil
ZEDQA r6p taxi drive right t=11 push=50000 fwd=-0.25,0.25,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=91s heading=nil
ZEDQA r6p taxi drive right t=12 push=50000 fwd=-0.24,0.26,-0.94 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=92s heading=nil
ZEDQA r6p taxi drive right t=13 push=50000 fwd=-0.24,0.26,-0.93 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=93s heading=nil
ZEDQA r6p taxi drive right t=14 push=50000 fwd=-0.24,0.27,-0.93 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=94s heading=nil
ZEDQA r6p taxi drive right t=15 push=50000 fwd=-0.24,0.28,-0.93 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=95s heading=nil
ZEDQA r6p taxi drive right t=16 push=50000 fwd=-0.24,0.30,-0.93 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=96s heading=nil
ZEDQA r6p taxi drive right t=17 push=50000 fwd=-0.24,0.31,-0.92 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=97s heading=nil
ZEDQA r6p taxi drive right t=18 push=50000 fwd=-0.24,0.31,-0.92 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=98s heading=nil
ZEDQA r6p taxi drive right t=19 push=50000 fwd=-0.23,0.33,-0.92 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=100s heading=nil
ZEDQA r6p taxi drive right t=20 push=50000 fwd=-0.23,0.34,-0.91 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=101s heading=nil
ZEDQA r6p taxi drive right t=21 push=50000 fwd=-0.23,0.36,-0.90 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=102s heading=nil
ZEDQA r6p taxi drive right t=22 push=50000 fwd=-0.23,0.38,-0.90 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=103s heading=nil
ZEDQA r6p taxi drive right t=23 push=50000 fwd=-0.23,0.39,-0.89 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=104s heading=nil
ZEDQA r6p taxi drive right t=24 push=50000 fwd=-0.23,0.42,-0.88 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=105s heading=nil
ZEDQA r6p taxi drive brake t=1 push=50000 fwd=-0.22,0.43,-0.88 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=106s heading=nil
ZEDQA r6p taxi drive brake t=2 push=50000 fwd=-0.22,0.42,-0.88 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=107s heading=nil
ZEDQA r6p taxi drive brake t=3 push=50000 fwd=-0.23,0.41,-0.88 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=108s heading=nil
ZEDQA r6p taxi drive brake t=4 push=50000 fwd=-0.23,0.40,-0.89 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=109s heading=nil
ZEDQA r6p taxi drive brake t=5 push=50000 fwd=-0.23,0.39,-0.89 kmh=0.0 yaw=0.00 hula=0 fare=2.00 miles=0.209 wait=110s heading=nil
ZEDQA r6p taxi drove: max 25.6 km/h, hula frames 0,1,0,1,0,1,0,1,0,1,0,1,0,2,0,2,0, fare 1.75 -> 2.00, fifths 0.190 -> 0.209 mi
ZEDQA r6p taxi PASS the first fifth of a mile clicked: fare 1.75 -> 2.00
ZEDQA r6p taxi stopped: hula=0
ZEDQA r6p taxi key out: keysIn=false meterOn=false fare=0.00 extras=0.00
ZEDQA r6p keep: skipped (the reload check ran in this game)
ZEDQA r6p back home 10985,11301
ZEDQA r6p errors=0
ZEDQA r6p DONE
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
```
