# ZeD-UI regression - 2026-11-04 21:06 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-04 21:06:42 |
| Finished | 2026-11-04 21:12:29 (5 min 46 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/perf_motion.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 20857 to 20860 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 20859, 20860)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | perf_motion.lua | pmo | PASS | 259 |  |  |

## Scripts

### 1. perf_motion.lua (`ZEDQA pmo`) - PASS, 259 s

- go 20858 at 21:07:48

```text
LOG : Lua f:208 st:7,666,707> ZEDQA pmo start
LOG : Lua f:208 st:7,666,707> [ZeD.QA] run #1 ok=true
LOG : Lua f:267 st:7,667,215> ZEDQA pmo ui vanilla, session mp; to the mall
LOG : General f:661 st:7,674,917> [04-11-26 21:07:57.081][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:679 st:7,675,288> ZEDQA pmo line 13922,5780 to 13922,5803 (28 containers along it)
LOG : General f:767 st:7,679,126> [04-11-26 21:08:01.290][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:768 st:7,679,167> [04-11-26 21:08:01.331][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:808 st:7,680,578> [04-11-26 21:08:02.741][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:846 st:7,681,919> [04-11-26 21:08:04.083][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:849 st:7,682,031> [04-11-26 21:08:04.195][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:887 st:7,683,394> [04-11-26 21:08:05.556][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:887 st:7,683,396> [04-11-26 21:08:05.560][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:928 st:7,684,896> [04-11-26 21:08:07.060][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:928 st:7,684,898> [04-11-26 21:08:07.062][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:935 st:7,685,148> [04-11-26 21:08:07.311][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:968 st:7,686,347> [04-11-26 21:08:08.511][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:968 st:7,686,350> [04-11-26 21:08:08.514][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1010 st:7,687,817> [04-11-26 21:08:09.982][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1022 st:7,688,252> [04-11-26 21:08:10.415][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1048 st:7,689,176> [04-11-26 21:08:11.340][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1052 st:7,689,317> [04-11-26 21:08:11.481][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1083 st:7,690,467> [04-11-26 21:08:12.630][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1109 st:7,691,341> [04-11-26 21:08:13.505][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1129 st:7,692,034> [04-11-26 21:08:14.198][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1151 st:7,692,813> [04-11-26 21:08:14.977][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1195 st:7,694,247> [04-11-26 21:08:16.411][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1211 st:7,694,780> [04-11-26 21:08:16.944][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:1514 st:7,704,805> ZEDQA pmo RES|vanilla|mp|1|hud_still|587|29.4|34.02|34|43|47|68|305|2|0
LOG : Lua f:2268 st:7,730,384> ZEDQA pmo RES|vanilla|mp|1|win_still|590|29.5|33.89|34|42|44|51|304|1|0
LOG : Lua f:3333 st:7,765,939> ZEDQA pmo RES|vanilla|mp|1|hud_walk|902|30.1|33.25|33|41|46|61|425|4|0
LOG : Lua f:4405 st:7,801,515> ZEDQA pmo RES|vanilla|mp|1|win_walk|904|30.1|33.18|33|40|44|55|413|1|0
LOG : Lua f:5177 st:7,827,075> ZEDQA pmo RES|vanilla|mp|2|hud_still|602|30.1|33.18|33|41|44|48|272|0|0
LOG : Lua f:5939 st:7,852,613> ZEDQA pmo RES|vanilla|mp|2|win_still|596|29.8|33.50|33|41|42|50|282|0|0
LOG : Lua f:6977 st:7,888,172> ZEDQA pmo RES|vanilla|mp|2|hud_walk|872|29.1|34.37|34|42|48|58|457|4|0
LOG : Lua f:7986 st:7,923,779> ZEDQA pmo RES|vanilla|mp|2|win_walk|848|28.3|35.35|35|44|50|170|488|8|1
LOG : Lua f:8000 st:7,924,300> ZEDQA pmo DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
