# ZeD-UI regression - 2026-10-26 21:16 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 21:16:28 |
| Finished | 2026-10-26 21:18:56 (2 min 27 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\AppData\Local\Temp\claude\C--Users-danie-Zomboid\989d1212-0f15-49ba-a371-9ee134c38e7f\scratchpad\r3\qc_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 13817 to 13820 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13819, 13820)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_quick_chords.lua | qc | WARN | 20 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13817 at 21:17:59

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_quick_chords.lua (`ZEDQA qc`) - WARN, 20 s

- go 13818 at 21:18:03
- 1 ERR line(s)
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #2 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
ZEDQA qc LB + X picks Base.HandTorch in none (brighter than the torch): that light is checked
ZEDQA qc LB+A = character:3 (Character > Eat): Eat
ZEDQA qc PASS LB+A: the default names a slice
ZEDQA qc LB+B = character:4 (Character > Drink): Drink
ZEDQA qc PASS LB+B: the default names a slice
ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
ZEDQA qc PASS LB+X: the default names a slice
ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
ZEDQA qc PASS LB+Y: the default names a slice
ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
ZEDQA qc PASS LB+L3: the default names a slice
ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
ZEDQA qc PASS LB+R3: the default names a slice
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid [off: Nothing to treat, no medicine on you.]
ZEDQA qc PASS RB+A: the default names a slice
ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
ZEDQA qc PASS RB+B: the default names a slice
ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
ZEDQA qc PASS RB+X: the default names a slice
ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
ZEDQA qc PASS RB+Y: the default names a slice
ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
ZEDQA qc PASS RB+L3: the default names a slice
ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
ZEDQA qc PASS RB+R3: the default names a slice
ZEDQA qc LB + X queued: ISEquipWeaponAction
ZEDQA qc PASS LB + X: the game's prompts never saw X
ZEDQA qc PASS a light for LB + X
ZEDQA qc PASS LB + X: the light is in a hand
ZEDQA qc PASS LB + X: the light is on
ZEDQA qc PASS LB + X again: the light is off
ZEDQA qc LB + X from a bag: skipped, LB + X picks Base.HandTorch in a hand or on the belt first
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
ZEDQA qc PASS LB + Y (smoke): the game queues its action
ZEDQA qc said: No QA Gone on you.
ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
ZEDQA qc PASS the Here and now wheel is open
ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
ZEDQA qc PASS the bubble says what it did
ZEDQA qc PASS opened again: Crouch shows RB + Y
ZEDQA qc PASS ZeD setup is open on the pause screen
ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
ZEDQA qc FAIL ZeD setup has Put things back
ZEDQA qc the list for LB+A: 87 items, 79 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc 1 failed
ZEDQA qc DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
