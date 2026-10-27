# ZeD-UI regression - 2026-10-26 19:54 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 19:54:39 |
| Finished | 2026-10-26 20:08:41 (14 min 2 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_C.txt (8 scripts) |
| Result | **1/8 pass**, 0 warn, 0 fail, 1 timeout, 6 not run |
| Go numbers | 13734 to 13738 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_r3_C.lua: no DONE within 600 s; the script may still be running in the game
- quit: the game was still running after the quit (go 13736, 13737, 13738); close it by hand
- ZeD settings NOT put back (the game is still running): copy C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-26_1954_mods_fullscreen4k.md.modoptions.ini over C:\Users\danie\Zomboid\Lua\ModOptions.ini once it has closed

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_C.lua | r3C | **TIMEOUT** | 601 | zqa_r3C_1_loot.png, zqa_r3C_2_menu_apple.png, zqa_r3C_3_menu_world.png, zqa_r3C_4_tip_shirt_zed.png, zqa_r3C_5_tip_shirt_safe.png, zqa_r3C_4_tip_book_zed.png, zqa_r3C_5_tip_book_safe.png, zqa_r3C_4_tip_vhs_zed.png, zqa_r3C_5_tip_vhs_safe.png, zqa_r3C_4_tip_seed_zed.png, zqa_r3C_5_tip_seed_safe.png, zqa_r3C_6_char_equip.png, zqa_r3C_6_char_health.png, zqa_r3C_6_char_skills.png, zqa_r3C_6_char_identity.png, zqa_r3C_7_world_craft.png, zqa_r3C_7_world_build.png, zqa_r3C_7_world_maps.png, zqa_r3C_8_skills_xp.png, zqa_r3C_9_char_traits.png | no DONE within 600 s; the script may still be running in the game |
| 3 | zedqa_traits.lua | tas | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |
| 4 | suite_tabs.lua | tabs | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |
| 5 | zedqa_exinfo.lua | ex | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |
| 6 | zedqa_charinfo.lua | ci | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |
| 7 | zedqa_moodles.lua | mood | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |
| 8 | zedqa_messages.lua | msg | SKIP |  |  | not run: no DONE within 600 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13734 at 19:56:24

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_C.lua (`ZEDQA r3C`) - TIMEOUT, 601 s

- go 13735 at 19:56:28
- no DONE within 600 s; the script may still be running in the game
- screenshots: zqa_r3C_1_loot.png, zqa_r3C_2_menu_apple.png, zqa_r3C_3_menu_world.png, zqa_r3C_4_tip_shirt_zed.png, zqa_r3C_5_tip_shirt_safe.png, zqa_r3C_4_tip_book_zed.png, zqa_r3C_5_tip_book_safe.png, zqa_r3C_4_tip_vhs_zed.png, zqa_r3C_5_tip_vhs_safe.png, zqa_r3C_4_tip_seed_zed.png, zqa_r3C_5_tip_seed_safe.png, zqa_r3C_6_char_equip.png, zqa_r3C_6_char_health.png, zqa_r3C_6_char_skills.png, zqa_r3C_6_char_identity.png, zqa_r3C_7_world_craft.png, zqa_r3C_7_world_build.png, zqa_r3C_7_world_maps.png, zqa_r3C_8_skills_xp.png, zqa_r3C_9_char_traits.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3C start
[ZeD.QA] run #2 ok=true
ZEDQA r3C shot zqa_r3C_1_loot.png
ZEDQA r3C ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_2_menu_apple.png
ZEDQA r3C world menu: Sit on ground, Walk to
ZEDQA r3C shot zqa_r3C_3_menu_world.png
ZEDQA r3C shot zqa_r3C_4_tip_shirt_zed.png
ZEDQA r3C tip shirt zed 238x96
ZEDQA r3C shot zqa_r3C_5_tip_shirt_safe.png
ZEDQA r3C tip shirt safe 238x93
ZEDQA r3C shot zqa_r3C_4_tip_book_zed.png
ZEDQA r3C tip book zed 297x79
ZEDQA r3C shot zqa_r3C_5_tip_book_safe.png
ZEDQA r3C tip book safe 297x76
ZEDQA r3C shot zqa_r3C_4_tip_vhs_zed.png
ZEDQA r3C tip vhs zed 189x45
ZEDQA r3C shot zqa_r3C_5_tip_vhs_safe.png
ZEDQA r3C tip vhs safe 189x42
ZEDQA r3C shot zqa_r3C_4_tip_seed_zed.png
ZEDQA r3C tip seed zed 202x79
ZEDQA r3C shot zqa_r3C_5_tip_seed_safe.png
ZEDQA r3C tip seed safe 202x76
ZEDQA r3C ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_6_char_equip.png
ZEDQA r3C shot zqa_r3C_6_char_health.png
ZEDQA r3C shot zqa_r3C_6_char_skills.png
ZEDQA r3C shot zqa_r3C_6_char_identity.png
ZEDQA r3C shot zqa_r3C_7_world_craft.png
ZEDQA r3C shot zqa_r3C_7_world_build.png
ZEDQA r3C shot zqa_r3C_7_world_maps.png
ZEDQA r3C ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_8_skills_xp.png
ZEDQA r3C shot zqa_r3C_9_char_traits.png
```

### 3. zedqa_traits.lua (`ZEDQA tas`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

### 4. suite_tabs.lua (`ZEDQA tabs`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

### 5. zedqa_exinfo.lua (`ZEDQA ex`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

### 6. zedqa_charinfo.lua (`ZEDQA ci`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

### 7. zedqa_moodles.lua (`ZEDQA mood`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

### 8. zedqa_messages.lua (`ZEDQA msg`) - SKIP, not run

- not run: no DONE within 600 s; the script may still be running in the game

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: General f:N at InputScript.OnPostWorldDictionaryInit> MakeBoneForearmArmor item not found: LabItems.LabSmallRandomHumanBones. line: item 5 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2]
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
