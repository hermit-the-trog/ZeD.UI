# ZeD-UI regression - 2026-11-05 15:11 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 15:11:41 |
| Finished | 2026-11-05 15:14:18 (2 min 37 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/you/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/after_b825.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 21132 to 21137 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21136, 21137)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_bar_step.lua | bst | WARN | 4 |  | 1 ERR line(s) |
| 3 | zedqa_btn_look.lua | bnl | PASS | 25 | zqa_bnl_dark_hand.png, zqa_bnl_dark_corners.png, zqa_bnl_dark_wash.png, zqa_bnl_dark_ants.png, zqa_bnl_hicon_hand.png, zqa_bnl_hicon_corners.png, zqa_bnl_hicon_wash.png, zqa_bnl_hicon_ants.png, zqa_bnl_light_hand.png, zqa_bnl_light_corners.png, zqa_bnl_light_wash.png, zqa_bnl_light_ants.png |  |
| 4 | zedqa_prompts.lua | pr | PASS | 30 | zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21132 at 15:12:42

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_bar_step.lua (`ZEDQA bst`) - WARN, 4 s

- go 21133 at 15:12:48
- 1 ERR line(s)

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA bst arrow: 42.0 px, a row is 42 px, the bar's height 486, range 415
ZEDQA bst PASS an arrow moves one row
ZEDQA bst track: 415.0 px against 90% of the view 437
ZEDQA bst FAIL the track moves about a page
ZEDQA bst DONE
```

### 3. zedqa_btn_look.lua (`ZEDQA bnl`) - PASS, 25 s

- go 21134 at 15:12:55
- screenshots: zqa_bnl_dark_hand.png, zqa_bnl_dark_corners.png, zqa_bnl_dark_wash.png, zqa_bnl_dark_ants.png, zqa_bnl_hicon_hand.png, zqa_bnl_hicon_corners.png, zqa_bnl_hicon_wash.png, zqa_bnl_hicon_ants.png, zqa_bnl_light_hand.png, zqa_bnl_light_corners.png, zqa_bnl_light_wash.png, zqa_bnl_light_ants.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA bnl shot dark hand
ZEDQA bnl shot dark corners
ZEDQA bnl shot dark wash
ZEDQA bnl shot dark ants
ZEDQA bnl shot hicon hand
ZEDQA bnl shot hicon corners
ZEDQA bnl shot hicon wash
ZEDQA bnl shot hicon ants
ZEDQA bnl shot light hand
ZEDQA bnl shot light corners
ZEDQA bnl shot light wash
ZEDQA bnl shot light ants
ZEDQA bnl DONE
```

### 4. zedqa_prompts.lua (`ZEDQA pr`) - PASS, 30 s

- go 21135 at 15:13:24
- screenshots: zqa_pr_01_sleep.png, zqa_pr_02_kill.png, zqa_pr_03_note.png, zqa_pr_04_rename.png, zqa_pr_05_rename_empty.png, zqa_pr_06_keyboard.png, zqa_pr_07_alarm.png, zqa_pr_08_timer.png, zqa_pr_09_help.png, zqa_pr_10_rich_question.png, zqa_pr_11_gp_question.png, zqa_pr_12_gp_question_no.png, zqa_pr_13_gp_kill.png, zqa_pr_14_gp_text.png, zqa_pr_15_gp_keyboard.png, zqa_pr_16_gp_alarm.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pr start
[ZeD.QA] run #4 ok=true
ZEDQA pr sleep Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr mouse 1922,1081
ZEDQA pr answer sleep internal=NO parentKind=question entry=nil
ZEDQA pr kill Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr kill costly=true
ZEDQA pr kill after No Type=ZeD_Prompt kind=question x=1659 y=948 w=526 h=265 visible=false top=false
ZEDQA pr note Type=ZeD_Prompt kind=note x=1578 y=947 w=683 h=265 visible=false top=false
ZEDQA pr answer note internal=OK parentKind=note entry=nil
ZEDQA pr after Escape: note visible=false pause=false
ZEDQA pr rename: no bag, plain box
ZEDQA pr rename Type=ZeD_Prompt kind=text x=1624 y=933 w=595 h=295 visible=false top=false
ZEDQA pr empty: yes.enable=false why=Can't be empty.
ZEDQA pr long: yes.enable=false why=Character limit: 12
ZEDQA pr keyboard Type=ISOnScreenKeyboard zed=true IsVisible=false
ZEDQA pr keyboard Type=ISOnScreenKeyboard kind=nil x=1428 y=1241 w=985 h=410 visible=false top=false
ZEDQA pr rename under keyboard Type=ZeD_Prompt kind=text x=1624 y=932 w=595 h=295 visible=true top=true
ZEDQA pr typed: Go Bags! current=Go Bags!
ZEDQA pr after keyboard cancel: Go Bag kbVisible=false
ZEDQA pr answer rename internal=OK parentKind=text entry=Go Bag
ZEDQA pr alarm Type=ZeD_Prompt kind=alarm x=1657 y=862 w=525 h=435 visible=false top=false
ZEDQA pr alarm after pad: 7:20 on=false focus=tick
ZEDQA pr alarm synced 7:20 on=false
ZEDQA pr timer Type=ZeD_Prompt kind=timer x=1657 y=920 w=525 h=319 visible=false top=false
ZEDQA pr timer answer OK time=35
ZEDQA pr help Type=ZeD_Prompt kind=rich x=1435 y=739 w=770 h=681 visible=false top=false
ZEDQA pr help blocks=5 contentH=486.67578125 maxScroll=0
ZEDQA pr help after OK visible=false
ZEDQA pr forget Type=ZeD_Prompt kind=rich x=1582 y=948 w=679 h=265 visible=false top=false
ZEDQA pr forget costly=false
ZEDQA pr answer forget internal=NO parentKind=rich entry=nil
ZEDQA pr subclass build ok=true kind=nil Type=ISConfirmMonitorSettings
ZEDQA pr open prompts left=0
ZEDQA pr gp focus=yes
ZEDQA pr gp after left focus=no
ZEDQA pr answer gp sleep internal=NO parentKind=question entry=nil
ZEDQA pr gp text focus=field
ZEDQA pr answer gp rename internal=CANCEL parentKind=text entry=Duffel Bag
ZEDQA pr gp open prompts left=0
ZEDQA pr DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
