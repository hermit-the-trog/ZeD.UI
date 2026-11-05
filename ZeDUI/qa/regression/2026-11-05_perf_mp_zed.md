# ZeD-UI regression - 2026-11-04 20:29 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-04 20:29:06 |
| Finished | 2026-11-04 20:34:52 (5 min 45 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/perf_motion.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 20846 to 20849 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 20848, 20849)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | perf_motion.lua | pmo | PASS | 258 |  |  |

## Scripts

### 1. perf_motion.lua (`ZEDQA pmo`) - PASS, 258 s

- go 20847 at 20:30:12

```text
LOG : Lua f:139 st:5,410,216> [ZeD.QA] state #1 speed=1 paused=false player=10637,10267 grid=19 inCar=false vehicles=7 missing=get
LOG : Lua f:139 st:5,410,218> [ZeD.QA] windows reset (R)
LOG : Lua f:139 st:5,410,219> ZEDQA pmo start
LOG : Lua f:139 st:5,410,219> [ZeD.QA] run #1 ok=true
LOG : Lua f:187 st:5,410,729> ZEDQA pmo ui zed, session mp; to the mall
LOG : Lua f:862 st:5,418,794> ZEDQA pmo line 13922,5780 to 13922,5803 (28 containers along it)
LOG : Lua f:2217 st:5,448,257> ZEDQA pmo RES|zed|mp|1|hud_still|933|46.6|21.42|21|28|34|56|10|2|0
LOG : Lua f:3185 st:5,473,820> ZEDQA pmo RES|zed|mp|1|win_still|755|37.8|26.47|26|33|36|58|27|4|0
LOG : General f:3816 st:5,489,885> [04-11-26 20:31:32.047][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3822 st:5,490,069> [04-11-26 20:31:32.232][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3883 st:5,491,787> [04-11-26 20:31:33.949][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3908 st:5,492,462> [04-11-26 20:31:34.624][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3934 st:5,493,208> [04-11-26 20:31:35.370][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3972 st:5,494,251> [04-11-26 20:31:36.413][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4018 st:5,495,519> [04-11-26 20:31:37.681][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4122 st:5,498,547> [04-11-26 20:31:40.708][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4139 st:5,499,025> [04-11-26 20:31:41.186][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4143 st:5,499,155> [04-11-26 20:31:41.317][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4172 st:5,499,980> [04-11-26 20:31:42.142][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4217 st:5,501,223> [04-11-26 20:31:43.386][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4233 st:5,501,662> [04-11-26 20:31:43.825][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4254 st:5,502,259> [04-11-26 20:31:44.420][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4268 st:5,502,653> [04-11-26 20:31:44.815][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4271 st:5,502,868> [04-11-26 20:31:45.030][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4281 st:5,503,181> [04-11-26 20:31:45.342][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4304 st:5,503,817> [04-11-26 20:31:45.980][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4316 st:5,504,151> [04-11-26 20:31:46.314][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4332 st:5,504,596> [04-11-26 20:31:46.759][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4332 st:5,504,600> [04-11-26 20:31:46.763][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4358 st:5,505,309> [04-11-26 20:31:47.472][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4366 st:5,505,539> [04-11-26 20:31:47.700][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4384 st:5,506,032> [04-11-26 20:31:48.194][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4384 st:5,506,037> [04-11-26 20:31:48.200][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4387 st:5,506,142> [04-11-26 20:31:48.305][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4415 st:5,506,968> [04-11-26 20:31:49.130][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4418 st:5,507,050> [04-11-26 20:31:49.213][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4427 st:5,507,304> [04-11-26 20:31:49.466][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4433 st:5,507,491> [04-11-26 20:31:49.654][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4433 st:5,507,496> [04-11-26 20:31:49.659][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4435 st:5,507,577> [04-11-26 20:31:49.739][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4452 st:5,508,088> [04-11-26 20:31:50.250][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4463 st:5,508,391> [04-11-26 20:31:50.553][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4466 st:5,508,513> [04-11-26 20:31:50.676][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:4498 st:5,509,383> ZEDQA pmo RES|zed|mp|1|hud_walk|1066|35.5|28.12|27|36|45|146|107|9|1
LOG : Lua f:5909 st:5,544,950> ZEDQA pmo RES|zed|mp|1|win_walk|1194|39.8|25.12|25|31|36|53|22|2|0
LOG : Lua f:6931 st:5,570,492> ZEDQA pmo RES|zed|mp|2|hud_still|804|40.2|24.86|24|30|34|56|11|4|0
LOG : Lua f:7946 st:5,596,015> ZEDQA pmo RES|zed|mp|2|win_still|797|39.8|25.08|25|31|34|54|10|2|0
LOG : Lua f:9391 st:5,631,564> ZEDQA pmo RES|zed|mp|2|hud_walk|1230|41.0|24.38|24|30|34|58|14|5|0
LOG : Lua f:10815 st:5,667,099> ZEDQA pmo RES|zed|mp|2|win_walk|1207|40.2|24.84|24|31|36|54|23|4|0
LOG : Lua f:10836 st:5,667,612> ZEDQA pmo DONE
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
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
