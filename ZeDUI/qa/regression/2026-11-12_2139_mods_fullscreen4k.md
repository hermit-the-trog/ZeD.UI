# ZeD-UI regression - 2026-11-12 21:40 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 21:40:17 |
| Finished | 2026-11-12 21:50:59 (10 min 41 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | not launched |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\_b12r2_lc_manifest.txt (1 scripts) |
| Result | **0/1 pass**, 0 warn, 0 fail, 0 timeout, 1 not run |
| Go numbers | 26042 to 26042 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- runner stopped: the game never reached 'game loading took' (5 minutes) (zedqa_run.ps1 line 551)
- quit: quit (go 26042)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | _b12r2_lc.lua | lc | SKIP |  |  | not run: the runner stopped |

## Scripts

### 1. _b12r2_lc.lua (`ZEDQA lc`) - SKIP, not run

- not run: the runner stopped

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
```
