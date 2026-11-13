# ZeD-UI regression - 2026-11-12 17:01 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 17:01:54 |
| Finished | 2026-11-12 17:05:37 (3 min 43 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\msc_run1_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 25758 to 25761 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 25760, 25761)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 3 |  |  |
| 2 | zedqa_msc_run1.lua | msc1 | PASS | 95 | zqa_msc1_1_before_hood.png, zqa_msc1_2_vehicle_tab_hood_open.png, zqa_msc1_3_engine_right_click.png, zqa_msc1_4_after_inspect.png, zqa_msc1_5_inspect_5s_later.png, zqa_msc1_6_outside_wheel_v_key.png, zqa_msc1_7_outside_pad_vehicle.png, zqa_msc1_8_world_menu_on_car.png, zqa_msc1_9_after_push_key.png, zqa_msc1_10_inside_wheel_v_key.png, zqa_msc1_11_inside_pad_vehicle.png, zqa_msc1_12_inside_wheel_ecu_v_key.png, zqa_msc1_13_inside_pad_vehicle_ecu.png, zqa_msc1_14_ecu_window.png, zqa_msc1_15_ecu_window_5s.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 3 s

- go 25758 at 17:03:26

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=30 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_msc_run1.lua (`ZEDQA msc1`) - PASS, 95 s

- go 25759 at 17:03:32
- screenshots: zqa_msc1_1_before_hood.png, zqa_msc1_2_vehicle_tab_hood_open.png, zqa_msc1_3_engine_right_click.png, zqa_msc1_4_after_inspect.png, zqa_msc1_5_inspect_5s_later.png, zqa_msc1_6_outside_wheel_v_key.png, zqa_msc1_7_outside_pad_vehicle.png, zqa_msc1_8_world_menu_on_car.png, zqa_msc1_9_after_push_key.png, zqa_msc1_10_inside_wheel_v_key.png, zqa_msc1_11_inside_pad_vehicle.png, zqa_msc1_12_inside_wheel_ecu_v_key.png, zqa_msc1_13_inside_pad_vehicle_ecu.png, zqa_msc1_14_ecu_window.png, zqa_msc1_15_ecu_window_5s.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=30 missing=get
[ZeD.QA] windows reset (R)
ZEDQA msc1 start (89 steps)
[ZeD.QA] run #2 ok=true
ZEDQA msc1 car Base.CarNormal at 929,13040
ZEDQA msc1 MSC loaded: true | EngineComponents true | VehiclePush true | AnimalTowClient true
ZEDQA msc1 initialized=true hoodOpen=false canAccessEngine=false
ZEDQA msc1 ECU installed (as spawned) = false
ZEDQA msc1 before the hood: no Summer Car engine window on the UI list
ZEDQA msc1 before the hood: game mechanics window 1520,767 800x600 reallyVisible=false vehicle=false msc_lastCanAccess=nil msc_userDismissed=nil
ZEDQA msc1 shot 1_before_hood
ZEDQA msc1 onMechanic called
ZEDQA msc1 hood open after 3048 ms; canAccessEngine=true tab inspected=false
ZEDQA msc1 Summer Car window seen on 0 of 318 ticks; first at nil ms, last at nil ms into the watch
ZEDQA msc1 after the hood is open: no Summer Car engine window on the UI list
ZEDQA msc1 after the hood is open: game mechanics window 1520,767 800x600 reallyVisible=false vehicle=false msc_lastCanAccess=nil msc_userDismissed=nil
ZEDQA msc1 World window tab vehicle | vehicle tab inspected true | World window 1929,0 1617x735
ZEDQA msc1 shot 2_vehicle_tab_hood_open
ZEDQA msc1 tab zones: mech:sort:area, mech:cat:engine, mech:row:Muffler, mech:row:EngineDoor, mech:row:Battery, mech:row:Engine, mech:row:Heater, mech:row:Windshield, mech:row:Radio, mech:row:HeadlightLeft, mech:row:HeadlightRight, mech:cat:gastank, mech:row:GasTank, mech:cat:tire, mech:row:TireFrontLeft, mech:row:BrakeFrontLeft, mech:row:SuspensionFrontLeft, mech:row:TireFrontRight, mech:row:BrakeFrontRight, mech:row:SuspensionFrontRight, mech:row:TireRearLeft, mech:row:BrakeRearLeft, mech:row:SuspensionRearLeft, mech:row:TireRearRight, mech:row:BrakeRearRight, mech:row:SuspensionRearRight, mech:cat:lights, mech:row:HeadlightRearLeft, mech:row:HeadlightRearRight, mech:cat:door, mech:row:DoorFrontLeft, mech:row:WindowFrontLeft, mech:row:DoorFrontRight, mech:row:WindowFrontRight, mech:row:DoorRearLeft, mech:row:WindowRearLeft, mech:row:DoorRearRight, mech:row:WindowRearRight, mech:cat:bodywork, mech:row:TrunkDoor, mech:row:TruckBed, mech:row:WindshieldRear, mech:cat:seat, mech:row:SeatFrontLeft, mech:row:SeatFrontRight, mech:row:SeatRearLeft, mech:row:SeatRearRight, mech:cat:Other, mech:row:GloveBox, mech:closehood, mech:sortMenu
ZEDQA msc1 engine row found: true
ZEDQA msc1 ZeD context menu for the Engine row (3 cells): DBG: ISVehicleMechanics.cheat=true (USE) | Remove engine at lift [greyed] (ACTION) | Inspect engine components (INFO)
ZEDQA msc1 the game's own part menu object holds: DBG: ISVehicleMechanics.cheat=true, Inspect engine components, Remove engine at lift [greyed]
ZEDQA msc1 shot 3_engine_right_click
ZEDQA msc1 Inspect engine components pressed: ok=true
ZEDQA msc1 after Inspect engine components: no Summer Car engine window on the UI list
ZEDQA msc1 after Inspect: game mechanics window 1520,767 800x600 reallyVisible=false vehicle=true msc_lastCanAccess=nil msc_userDismissed=false
ZEDQA msc1 shot 4_after_inspect
ZEDQA msc1 5 s later: no Summer Car engine window on the UI list
ZEDQA msc1 shot 5_inspect_5s_later
ZEDQA msc1 standing at car+0.0,+2.3: Push.validate valid=true reason=nil | game finds the car to interact with: true
ZEDQA msc1 push position found: true
ZEDQA msc1 outside wheel (the V key path, ZeD's wheel): visible=false, 0 slices |
ZEDQA msc1 shot 6_outside_wheel_v_key
ZEDQA msc1 outside pad wheel: World wheel's Vehicle slice off=nil
ZEDQA msc1 outside pad wheel (the pad's World > Vehicle wheel through ZeD): visible=true, 4 slices | 1:Vehicle Mechanics 2:Enter Vehicle 3:Push vehicle 4:Back
ZEDQA msc1 shot 7_outside_pad_vehicle
ZEDQA msc1 the car on the screen at 2066,1063 (zoom 1)
ZEDQA msc1 ZeD world context menu on the car (6 cells): Gardening (ACTION) | Sit on ground (ACTION) | Walk to (ACTION) | Vehicle (ACTION) | MSC: Dump vehicle diagnostics (ACTION) | Push vehicle (ACTION)
ZEDQA msc1 shot 8_world_menu_on_car
ZEDQA msc1 push hotkey bound to K: addKeyBinding ok=true | key now 37
ZEDQA msc1 Push.validate: valid=true reason=nil
ZEDQA msc1 OnKeyPressed saw K 1 time(s) (the engine delivered the real key to the Lua events)
ZEDQA msc1 push result: the car moved 0.45 squares, speed now 0.00 km/h; the character shoving: false
ZEDQA msc1 shot 9_after_push_key
ZEDQA msc1 seated=true
ZEDQA msc1 ECU installed (as spawned) = false initialized true
ZEDQA msc1 inside wheel (no ECU yet) (the V key path, ZeD's wheel): visible=false, 4 slices | 1:Vehicle Mechanics 2:Enter Vehicle 3:Push vehicle 4:Back
ZEDQA msc1 shot 10_inside_wheel_v_key
ZEDQA msc1 inside pad wheel (no ECU yet): World wheel's Vehicle slice off=nil
ZEDQA msc1 inside pad wheel (no ECU yet) (the pad's World > Vehicle wheel through ZeD): visible=true, 12 slices | 1:Switch Seat 2:Turn Headlights on 3:Turn AC/Heater on 4:Horn 5:Device Options 6:Open Window 7:Unlock all doors 8:Vehicle Mechanics 9:Not tired enough to sleep. [off] 10:Exit Vehicle 11:Dashboard / The D-pad on its controls. Back lets go. 12:Back
ZEDQA msc1 shot 11_inside_pad_vehicle
ZEDQA msc1 ECU forced on by vehicle mod data (was false): this is staging, the server would set it
ZEDQA msc1 inside wheel (ECU forced) (the V key path, ZeD's wheel): visible=false, 12 slices | 1:Switch Seat 2:Turn Headlights on 3:Turn AC/Heater on 4:Horn 5:Device Options 6:Open Window 7:Unlock all doors 8:Vehicle Mechanics 9:Not tired enough to sleep. [off] 10:Exit Vehicle 11:Dashboard / The D-pad on its controls. Back lets go. 12:Back
ZEDQA msc1 shot 12_inside_wheel_ecu_v_key
ZEDQA msc1 inside pad wheel (ECU forced): World wheel's Vehicle slice off=nil
ZEDQA msc1 inside pad wheel (ECU forced) (the pad's World > Vehicle wheel through ZeD): visible=true, 13 slices | 1:Switch Seat 2:Turn Headlights on 3:Turn AC/Heater on 4:Horn 5:Device Options 6:Open Window 7:Unlock all doors 8:Vehicle Mechanics 9:Not tired enough to sleep. [off] 10:Exit Vehicle 11:Open ECU diagnostics 12:Dashboard / The D-pad on its controls. Back lets go. 13:Back
ZEDQA msc1 shot 13_inside_pad_vehicle_ecu
ZEDQA msc1 ECU slice pressed (slice 11): ok=true
ZEDQA msc1 after the ECU slice: Summer Car engine window at 1670,764 size 500x631 visible=true title=MSC Engine Components tab=diagnostics placement=nil
ZEDQA msc1 shot 14_ecu_window
ZEDQA msc1 5 s after the ECU slice: Summer Car engine window at 1670,764 size 500x631 visible=true title=MSC Engine Components tab=diagnostics placement=nil
ZEDQA msc1 shot 15_ecu_window_5s
ZEDQA msc1 put back: car and key removed, push key unbound
ZEDQA msc1 DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
