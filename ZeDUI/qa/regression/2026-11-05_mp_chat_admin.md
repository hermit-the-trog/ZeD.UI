# ZeD-UI regression - 2026-11-05 10:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 10:27:21 |
| Finished | 2026-11-05 10:29:41 (2 min 20 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/mp_chat_admin.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 20918 to 20922 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 20921, 20922)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | mp_chat_admin.lua | mca | WARN | 49 |  | 1 ERR line(s) |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 20919 at 10:28:26

```text
LOG : Lua f:107 st:55,704,608> [ZeD.QA] state #1 speed=1 paused=false player=10693,9384 grid=19 inCar=false vehicles=1 missing=get
LOG : Lua f:107 st:55,704,609> [ZeD.QA] windows reset (R)
LOG : Lua f:107 st:55,704,610> ZEDQA pnw pinned both windows
LOG : Lua f:107 st:55,704,611> [ZeD.QA] run #1 ok=true
LOG : Lua f:127 st:55,704,881> ZEDQA pnw DONE
```

### 2. mp_chat_admin.lua (`ZEDQA mca`) - WARN, 49 s

- go 20920 at 10:28:30
- 1 ERR line(s)

```text
LOG : Lua f:527 st:55,709,017> [ZeD.QA] state #2 speed=1 paused=false player=10693,9384 grid=19 inCar=false vehicles=1 missing=get
LOG : Lua f:527 st:55,709,020> [ZeD.QA] windows reset (R)
LOG : Lua f:527 st:55,709,021> [ZeD.QA] run #2 ok=true
LOG : Lua f:561 st:55,709,325> ZEDQA mca chat active true, on belt true, unread 2, lines 2
LOG : Lua f:561 st:55,709,325> ZEDQA mca the game's chat box visible false
LOG : Lua f:675 st:55,710,528> ZEDQA mca chat window open true at 26,1460 770x455
LOG : Lua f:675 st:55,710,529> ZEDQA mca tabs general, private, admin
LOG : Lua f:675 st:55,710,533> ZEDQA mca send say: true
LOG : Lua f:927 st:55,713,034> ZEDQA mca PASS say came back (say, zedqa)
LOG : Lua f:927 st:55,713,037> ZEDQA mca send /all: true
LOG : Lua f:1214 st:55,715,536> ZEDQA mca PASS /all came back (general)
LOG : General f:1214 st:55,715,537> [05-11-26 10:28:37.702][info] Send message 'qa whisper 11186' for player 'zedqa' in whisper chat.
LOG : Lua f:1214 st:55,715,539> ZEDQA mca send whisper to self: true
LOG : Lua f:1504 st:55,718,036> ZEDQA mca NOTE whisper to self came back false (the game may refuse a whisper to yourself)
LOG : Lua f:1504 st:55,718,037> ZEDQA mca send /a: true
LOG : Lua f:1796 st:55,720,539> ZEDQA mca PASS admin chat came back (admin)
LOG : Lua f:1967 st:55,723,043> ZEDQA mca PASS a line with the window shut counts on the belt: 1
LOG : Lua f:3594 st:55,737,048> ZEDQA mca after 14 s idle: window dim nil (field names guessed; see mca_dim.png)
LOG : Lua f:3697 st:55,739,633> ZEDQA mca World tabs []
LOG : Lua f:3697 st:55,739,634> ZEDQA mca FAIL the Admin tab on the World window (admin)
LOG : Lua f:3868 st:55,742,147> ZEDQA mca admin hits (12): pick:p:zedqa, check:Invisible, check:GodMod, check:NoClip, check:FastMove, check:TimedActionInstant, check:UnlimitedCarry, check:UnlimitedEndurance, check:UnlimitedAmmo, check:KnowAllRecipes, check:BuildCheat, check:FarmingCheat
LOG : Lua f:3868 st:55,743,146> ZEDQA mca ticked GodMod
LOG : Lua f:3966 st:55,744,657> ZEDQA mca god mode was false, now true
LOG : Lua f:4000 st:55,745,157> ZEDQA mca More tools buttons 0
LOG : Lua f:4771 st:55,756,548> ZEDQA mca tickets known 0
LOG : Lua f:4771 st:55,756,549> ZEDQA mca DONE
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
