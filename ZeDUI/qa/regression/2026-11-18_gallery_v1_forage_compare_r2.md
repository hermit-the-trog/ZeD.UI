# ZeD-UI regression - 2026-11-18 16:49 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 16:49:12 |
| Finished | 2026-11-18 16:51:36 (2 min 23 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\gallery_v1_forage_compare.txt (10 scripts) |
| Result | **10/10 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 29827 to 29838 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29837, 29838)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_b10_glasses.lua | gls | PASS | 1 |  |  |
| 5 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 6 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 7 | gallery_v1_c2_common.lua | gv1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 8 | gallery_v1_forage_compare.lua | fcmp | PASS | 17 | zqa_fcmp_arrows.png, zqa_fcmp_hands.png | late output from unl (18 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29827 at 16:50:17

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 29828 at 16:50:22

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 29829 at 16:50:26

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #3 ok=true
ZEDQA g14l DONE
```

### 4. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 1 s

- go 29830 at 16:50:31

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls short sighted false, prescription glasses off
[ZeD.QA] run #4 ok=true
ZEDQA gls DONE
```

### 5. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29831 at 16:50:35

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #5 ok=true
ZEDQA hcn DONE
```

### 6. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29832 at 16:50:39

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 26.6 of 8 kg, 55 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 28 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 9.6 of 8 kg, 27 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #6 ok=true
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (x3)
```

### 7. gallery_v1_c2_common.lua (`ZEDQA gv1c`) - PASS, 1 s

- go 29833 at 16:50:44
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gv1c helpers ready | ZeD true | prelude car helpers true | load 9.6 of 8 kg, 27 items, Heavy Load 1
[ZeD.QA] run #7 ok=true
ZEDQA gv1c DONE
ZEDQA unl load 9.6 of 8 kg, 27 items, Heavy Load 1   (late output from unl)   (x4)
```

### 8. gallery_v1_forage_compare.lua (`ZEDQA fcmp`) - PASS, 17 s

- go 29834 at 16:50:48
- late output from unl (18 line(s), not counted)
- screenshots: zqa_fcmp_arrows.png, zqa_fcmp_hands.png

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fcmp start (16 steps)
[ZeD.QA] run #8 ok=true
ZEDQA fcmp start at 925,13040,0 | 9.6 of 8 kg, 27 items, Heavy Load 1 | look dark teal
ZEDQA fcmp at 931,13045, noon; search mode was false; find type Base.MushroomGeneric1
ZEDQA fcmp search mode true; zone BirchMixForest
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5b0cc1d2-Base.Egg at 923.3858032226562,13040.021484375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5ca1a54f-Base.Egg at 923.1469116210938,13043.138671875: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@84ff3af-Base.CarKey at 923.5050048828125,13049.94970703125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@454b9955-Base.CarKey at 924.8270263671875,13046.0126953125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@30b4c9de-Base.Egg at 924.467041015625,13053.08984375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@286d1111-Base.CarKey at 925.2689819335938,13037.083984375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@56edb060-Base.Disc_Retail at 925.9178466796875,13040.6298828125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@56edb060-Base.Spoon at 925.4456715583801,13040.401473999023: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@3b8d769e-Base.Egg at 925.095458984375,13052.3623046875: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@7f0f6db3-Base.Glasses_Prescription at 926.4496154785156,13040.49365234375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@68e14d7c-Base.CarKey at 926.2949829101562,13042.7607421875: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@96d81ed-Base.CarKey at 926.573974609375,13044.328125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@545a0f64-Base.KeyRing at 927.8930053710938,13038.37109375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@3a6c94a-Base.Egg at 927.1929931640625,13044.220703125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@4cdb8672-Base.BrokenGlass at 928.8140258789062,13040.490234375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@1f637134-Base.CarKey at 928.823974609375,13048.3232421875: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@1eb61496-Base.Twigs at 929.5174865722656,13039.7216796875: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@1eb61496-Base.TinCanEmpty at 929.4375,13039.50146484375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@1ab42ecf-Base.CarKey at 929.6279907226562,13042.2880859375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@1dd96f84-Base.CarKey at 929.7210083007812,13045.4912109375: seen true, identified true, pointer true
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@4f1ae12-Base.CarKey at 930.3900146484375,13037.83984375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@6969bc55-Base.Egg at 930.218994140625,13038.412109375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@3c968ba7-Base.KeyRing at 930.52001953125,13043.7216796875: seen true, identified true, pointer true
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5e0c57e4-Base.CarKey at 931.1619873046875,13052.9052734375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@6bfe6a3-Base.CarKey at 933.3270263671875,13047.28515625: seen true, identified true, pointer true
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5946a485-Base.CarKey at 934.0490112304688,13045.7216796875: seen true, identified true, pointer true
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5f946624-Base.Egg at 934.0128173828125,13046.4130859375: seen true, identified true, pointer true
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@734fcd49-Base.Egg at 935.3816528320312,13048.416015625: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@40684b38-Base.Egg at 936.4536743164062,13049.4052734375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@4851063e-Base.Dung_Sheep at 937.8330078125,13037.80078125: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@5b833aa6-Base.CarKey at 937.7150268554688,13041.712890625: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@21861db-Base.KeyRing at 938.3839721679688,13039.55859375: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@3bc79146-Base.CarKey at 939.1380004882812,13049.849609375: seen false, identified true, pointer false
ZEDQA fcmp settled find zedqa_fcmp_one at 934,13044: seen true, identified false, pointer true
ZEDQA fcmp settled find zedqa_fcmp_two at 929,13047: seen true, identified false, pointer true
ZEDQA fcmp settled find zedqa_fcmp_three at 932,13048: seen true, identified false, pointer true
ZEDQA fcmp settled find zedqa_fcmp_four at 928,13043: seen true, identified false, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@f0bc481-Base.WoolRaw at 922.3559324741364,13042.58039855957: seen false, identified true, pointer false
ZEDQA fcmp settled find zombie.iso.IsoGridSquare@23582ef6-Base.CarKey at 922.1119995117188,13052.515625: seen false, identified true, pointer false
ZEDQA fcmp settled finds 39: seen 9, identified 35, pointers 8
ZEDQA fcmp safe mode true (option was 1)
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5b0cc1d2-Base.Egg at 923.3858032226562,13040.021484375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5ca1a54f-Base.Egg at 923.1469116210938,13043.138671875: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@84ff3af-Base.CarKey at 923.5050048828125,13049.94970703125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@454b9955-Base.CarKey at 924.8270263671875,13046.0126953125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@30b4c9de-Base.Egg at 924.467041015625,13053.08984375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@286d1111-Base.CarKey at 925.2689819335938,13037.083984375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@56edb060-Base.Disc_Retail at 925.9178466796875,13040.6298828125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@56edb060-Base.Spoon at 925.4456715583801,13040.401473999023: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@3b8d769e-Base.Egg at 925.095458984375,13052.3623046875: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@7f0f6db3-Base.Glasses_Prescription at 926.4496154785156,13040.49365234375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@68e14d7c-Base.CarKey at 926.2949829101562,13042.7607421875: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@96d81ed-Base.CarKey at 926.573974609375,13044.328125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@545a0f64-Base.KeyRing at 927.8930053710938,13038.37109375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@3a6c94a-Base.Egg at 927.1929931640625,13044.220703125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@4cdb8672-Base.BrokenGlass at 928.8140258789062,13040.490234375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@1f637134-Base.CarKey at 928.823974609375,13048.3232421875: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@1eb61496-Base.Twigs at 929.5174865722656,13039.7216796875: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@1eb61496-Base.TinCanEmpty at 929.4375,13039.50146484375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@1ab42ecf-Base.CarKey at 929.6279907226562,13042.2880859375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@1dd96f84-Base.CarKey at 929.7210083007812,13045.4912109375: seen true, identified true, pointer true
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@4f1ae12-Base.CarKey at 930.3900146484375,13037.83984375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@6969bc55-Base.Egg at 930.218994140625,13038.412109375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@3c968ba7-Base.KeyRing at 930.52001953125,13043.7216796875: seen true, identified true, pointer true
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5e0c57e4-Base.CarKey at 931.1619873046875,13052.9052734375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@6bfe6a3-Base.CarKey at 933.3270263671875,13047.28515625: seen true, identified true, pointer true
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5946a485-Base.CarKey at 934.0490112304688,13045.7216796875: seen true, identified true, pointer true
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5f946624-Base.Egg at 934.0128173828125,13046.4130859375: seen true, identified true, pointer true
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@734fcd49-Base.Egg at 935.3816528320312,13048.416015625: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@40684b38-Base.Egg at 936.4536743164062,13049.4052734375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@4851063e-Base.Dung_Sheep at 937.8330078125,13037.80078125: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@5b833aa6-Base.CarKey at 937.7150268554688,13041.712890625: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@21861db-Base.KeyRing at 938.3839721679688,13039.55859375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@3bc79146-Base.CarKey at 939.1380004882812,13049.849609375: seen false, identified true, pointer false
ZEDQA fcmp arrows find zedqa_fcmp_one at 934,13044: seen true, identified false, pointer true
ZEDQA fcmp arrows find zedqa_fcmp_two at 929,13047: seen true, identified false, pointer true
ZEDQA fcmp arrows find zedqa_fcmp_three at 932,13048: seen true, identified false, pointer true
ZEDQA fcmp arrows find zedqa_fcmp_four at 928,13043: seen true, identified false, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@f0bc481-Base.WoolRaw at 922.3559324741364,13042.58039855957: seen false, identified true, pointer false
ZEDQA fcmp arrows find zombie.iso.IsoGridSquare@23582ef6-Base.CarKey at 922.1119995117188,13052.515625: seen false, identified true, pointer false
ZEDQA fcmp arrows finds 39: seen 9, identified 35, pointers 8
ZEDQA fcmp shot zqa_fcmp_arrows
ZEDQA fcmp load zqa_fcmp_arrows: 9.6 of 18 kg, 27 items, Heavy Load 0
ZEDQA fcmp overflow zqa_fcmp_arrows: none
ZEDQA fcmp where zqa_fcmp_arrows: 931,13045,0 nil
ZEDQA fcmp box zqa_fcmp_arrows character 1760,776-2080,1196
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA fcmp safe mode false (option was 1)
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5b0cc1d2-Base.Egg at 923.3858032226562,13040.021484375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5ca1a54f-Base.Egg at 923.1469116210938,13043.138671875: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@84ff3af-Base.CarKey at 923.5050048828125,13049.94970703125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@454b9955-Base.CarKey at 924.8270263671875,13046.0126953125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@30b4c9de-Base.Egg at 924.467041015625,13053.08984375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@286d1111-Base.CarKey at 925.2689819335938,13037.083984375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@56edb060-Base.Disc_Retail at 925.9178466796875,13040.6298828125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@56edb060-Base.Spoon at 925.4456715583801,13040.401473999023: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@3b8d769e-Base.Egg at 925.095458984375,13052.3623046875: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@7f0f6db3-Base.Glasses_Prescription at 926.4496154785156,13040.49365234375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@68e14d7c-Base.CarKey at 926.2949829101562,13042.7607421875: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@96d81ed-Base.CarKey at 926.573974609375,13044.328125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@545a0f64-Base.KeyRing at 927.8930053710938,13038.37109375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@3a6c94a-Base.Egg at 927.1929931640625,13044.220703125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@4cdb8672-Base.BrokenGlass at 928.8140258789062,13040.490234375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@1f637134-Base.CarKey at 928.823974609375,13048.3232421875: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@1eb61496-Base.Twigs at 929.5174865722656,13039.7216796875: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@1eb61496-Base.TinCanEmpty at 929.4375,13039.50146484375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@1ab42ecf-Base.CarKey at 929.6279907226562,13042.2880859375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@1dd96f84-Base.CarKey at 929.7210083007812,13045.4912109375: seen true, identified true, pointer true
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@4f1ae12-Base.CarKey at 930.3900146484375,13037.83984375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@6969bc55-Base.Egg at 930.218994140625,13038.412109375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@3c968ba7-Base.KeyRing at 930.52001953125,13043.7216796875: seen true, identified true, pointer true
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5e0c57e4-Base.CarKey at 931.1619873046875,13052.9052734375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@6bfe6a3-Base.CarKey at 933.3270263671875,13047.28515625: seen true, identified true, pointer true
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5946a485-Base.CarKey at 934.0490112304688,13045.7216796875: seen true, identified true, pointer true
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5f946624-Base.Egg at 934.0128173828125,13046.4130859375: seen true, identified true, pointer true
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@734fcd49-Base.Egg at 935.3816528320312,13048.416015625: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@40684b38-Base.Egg at 936.4536743164062,13049.4052734375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@4851063e-Base.Dung_Sheep at 937.8330078125,13037.80078125: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@5b833aa6-Base.CarKey at 937.7150268554688,13041.712890625: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@21861db-Base.KeyRing at 938.3839721679688,13039.55859375: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@3bc79146-Base.CarKey at 939.1380004882812,13049.849609375: seen false, identified true, pointer false
ZEDQA fcmp hands find zedqa_fcmp_one at 934,13044: seen true, identified false, pointer true
ZEDQA fcmp hands find zedqa_fcmp_two at 929,13047: seen true, identified false, pointer true
ZEDQA fcmp hands find zedqa_fcmp_three at 932,13048: seen true, identified false, pointer true
ZEDQA fcmp hands find zedqa_fcmp_four at 928,13043: seen true, identified false, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@f0bc481-Base.WoolRaw at 922.3559324741364,13042.58039855957: seen false, identified true, pointer false
ZEDQA fcmp hands find zombie.iso.IsoGridSquare@23582ef6-Base.CarKey at 922.1119995117188,13052.515625: seen false, identified true, pointer false
ZEDQA fcmp hands finds 39: seen 9, identified 35, pointers 8
ZEDQA fcmp shot zqa_fcmp_hands
ZEDQA fcmp load zqa_fcmp_hands: 9.6 of 18 kg, 27 items, Heavy Load 0
ZEDQA fcmp overflow zqa_fcmp_hands: none
ZEDQA fcmp where zqa_fcmp_hands: 931,13045,0 nil
ZEDQA fcmp box zqa_fcmp_hands character 1760,776-2080,1196
ZEDQA fcmp box zqa_fcmp_hands belt 1535,2034-2197,2132
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA fcmp put back: the finds gone, search mode false, the time
ZEDQA fcmp put back: 0 things given taken away, 0 light switches off, power and weather as they were, windows, place 925,13040
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA fcmp end: 2 shots, 0 not taken or failed
ZEDQA fcmp DONE
ZEDQA unl load 9.6 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29835 at 16:51:09

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 9.6 of 18 kg, 27 items, Heavy Load 0
ZEDQA rel put back 28 things; after: 26.6 of 18 kg, 55 items, Heavy Load 1 OVER
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 29836 at 16:51:13

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #10 ok=true
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
