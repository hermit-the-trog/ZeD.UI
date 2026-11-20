# ZeD-UI regression - 2026-11-20 02:20 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 02:20:03 |
| Finished | 2026-11-20 02:25:04 (5 min 0 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\perf_full.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30575 to 30579 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30578, 30579)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | perf_now.lua | pnow | PASS | 197 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30575 at 02:21:12

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
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 30576 at 02:21:18

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. perf_now.lua (`ZEDQA pnow`) - PASS, 197 s

- go 30577 at 02:21:22

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnow START scenes=8 settle=60 frames=600/600/240
[ZeD.QA] run #3 ok=true
ZEDQA pnow FRAME|hud|frames=600|avgMs=8.357|p95=12.0|worst=26
ZEDQA pnow UIE|hud|frames=600|frameMs=8.35|top-level=25 elements=813|sum=0.85 ms/frame
ZEDQA pnow UIE|hud|0.350 ms/frame|0.50 calls/frame|ZeD_BeltHUD prerender 662x98 d0 vis=true Belt
ZEDQA pnow UIE|hud|0.058 ms/frame|0.50 calls/frame|ISEquippedItem prerender 53x621 d0 vis=true
ZEDQA pnow UIE|hud|0.052 ms/frame|0.50 calls/frame|WaterMarkUI render 228x22 d0 vis=true
ZEDQA pnow UIE|hud|0.043 ms/frame|0.50 calls/frame|ZeD_Watch prerender 228x52 d0 vis=true Watch
ZEDQA pnow UIE|hud|0.033 ms/frame|0.50 calls/frame|ZeD_HintStripHUD prerender 10x10 d0 vis=true Hint strip
ZEDQA pnow UIE|hud|0.027 ms/frame|0.50 calls/frame|ZeD_MoodleLayer prerender 48x48 d0 vis=true Moodles
ZEDQA pnow UIE|hud|0.027 ms/frame|0.08 calls/frame|ISInventoryPage update 1280x711 d0 vis=false Inventory
ZEDQA pnow UIE|hud|0.022 ms/frame|1.00 calls/frame|ISButton render 48x36 d1 vis=true
ZEDQA pnow UIE|hud|0.020 ms/frame|0.50 calls/frame|ISButton render 228x23 d1 vis=true 42.22.2 3d39148846 pzBul
ZEDQA pnow UIE|hud|0.018 ms/frame|0.50 calls/frame|ISEquippedItem render 53x621 d0 vis=true
ZEDQA pnow UIE|hud|0.015 ms/frame|0.08 calls/frame|ISInventoryPage update 1280x711 d0 vis=false Ground
ZEDQA pnow UIE|hud|0.013 ms/frame|0.50 calls/frame|WaterMarkUI prerender 228x22 d0 vis=true
ZEDQA pnow UIE|hud|0.013 ms/frame|0.50 calls/frame|ZeD_ActionBarLayer prerender 1x1 d0 vis=true Action bar
ZEDQA pnow UIE|hud|0.012 ms/frame|0.50 calls/frame|ISButton prerender 228x23 d1 vis=true 42.22.2 3d39148846 pzBul
ZEDQA pnow UIE|hud|0.012 ms/frame|0.50 calls/frame|ZeD_MoodleNote render 1x1 d0 vis=true Moodle notes
ZEDQA pnow UIE|hud|0.012 ms/frame|0.08 calls/frame|ISHotbar update 194x82 d0 vis=true
ZEDQA pnow CEN|hud|frames=240|LEAN draw calls per frame=18.5|ISUIElement draw calls per frame=6.5|TM calls per frame=8.4
ZEDQA pnow CEN|hud|LEAN|17.5|ZeD_BeltHUD|drawTextureScaled 4.0, drawTextureScaledAspect 4.0, drawRect 4.0, drawRectBorder 3.0, drawText 2.5
ZEDQA pnow CEN|hud|LEAN|1.0|ZeD_Watch|drawTextureScaled 1.0
ZEDQA pnow CEN|hud|UIE|2.5|ISButton|drawTexture 0.5, drawTextureScaledAspect 0.5, drawRect 0.5, drawRectBorder 0.5, drawText 0.5
ZEDQA pnow CEN|hud|UIE|1.5|WaterMarkUI|drawTextRight 1.5
ZEDQA pnow CEN|hud|UIE|1.5|ZeD_MoodleLayer|drawTexture 1.5
ZEDQA pnow CEN|hud|UIE|1.0|ZeD_BeltHUD|setStencilRect 1.0
ZEDQA pnow CEN|hud|TM|4.9|MeasureStringX
ZEDQA pnow CEN|hud|TM|0.5|MeasureStringY
ZEDQA pnow CEN|hud|TM|3.0|getFontHeight
ZEDQA pnow FRAME|pair_loot|frames=600|avgMs=13.812|p95=22.0|worst=34
ZEDQA pnow PROF|pair_loot|frames=600|frameMs=14.65|sumPreRender=6.95
ZEDQA pnow PROF|pair_loot|4.412 ms/frame|1.69 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|pair_loot|0.895 ms/frame|3.38 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|pair_loot|0.757 ms/frame|1.69 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|pair_loot|0.518 ms/frame|1.69 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|pair_loot|0.292 ms/frame|3.38 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|pair_loot|0.050 ms/frame|0.27 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|pair_loot|0.027 ms/frame|1.69 calls/frame|ISPanel render 777x735 d1
ZEDQA pnow PROF|pair_loot|0.022 ms/frame|1.69 calls/frame|ZeD_Window render 777x735 d0
ZEDQA pnow PROF|pair_loot|0.017 ms/frame|1.69 calls/frame|ZeD_Panel render 651x650 d1
ZEDQA pnow PROF|pair_loot|0.007 ms/frame|3.38 calls/frame|ZeD_Panel render 63x650 d1
ZEDQA pnow PROF|pair_loot|0.005 ms/frame|0.68 calls/frame|ZeD_SearchField update 350x46 d2
ZEDQA pnow PROF|pair_loot|0.003 ms/frame|3.38 calls/frame|ZeD_Panel render 0x650 d1
ZEDQA pnow PROF|pair_loot|0.003 ms/frame|0.55 calls/frame|ZeD_Panel update 63x650 d1
ZEDQA pnow PROF|pair_loot|0.003 ms/frame|1.69 calls/frame|ISPanel prerender 777x735 d1
ZEDQA pnow CEN|pair_loot|frames=240|LEAN draw calls per frame=475.8|ISUIElement draw calls per frame=15.0|TM calls per frame=89.8
ZEDQA pnow CEN|pair_loot|LEAN|291.7|ZeD_Panel|drawRect 138.3, drawTextureScaled 70.0, drawText 56.7, drawTextureScaledAspect 24.2, drawRectBorder 2.5
ZEDQA pnow CEN|pair_loot|LEAN|90.8|ZeD_Window|drawRect 76.7, drawRectBorder 6.7, drawText 4.2, drawTextureScaledAspect 3.3
ZEDQA pnow CEN|pair_loot|LEAN|62.5|ZeD_WindowOverlay|drawRect 59.2, drawText 1.7, drawRectBorder 1.7
ZEDQA pnow CEN|pair_loot|LEAN|29.2|ZeD_BeltHUD|drawTextureScaled 6.7, drawTextureScaledAspect 6.7, drawRect 6.7, drawRectBorder 5.0, drawText 4.2
ZEDQA pnow CEN|pair_loot|LEAN|1.7|ZeD_Watch|drawTextureScaled 1.7
ZEDQA pnow CEN|pair_loot|UIE|4.2|ISButton|drawTexture 0.8, drawTextureScaledAspect 0.8, drawRect 0.8, drawRectBorder 0.8, drawText 0.8
ZEDQA pnow CEN|pair_loot|UIE|4.2|ZeD_Panel|setStencilRect 4.2
ZEDQA pnow CEN|pair_loot|UIE|2.5|WaterMarkUI|drawTextRight 2.5
ZEDQA pnow CEN|pair_loot|UIE|2.5|ZeD_MoodleLayer|drawTexture 2.5
ZEDQA pnow CEN|pair_loot|UIE|1.7|ZeD_BeltHUD|setStencilRect 1.7
ZEDQA pnow CEN|pair_loot|TM|67.3|MeasureStringX
ZEDQA pnow CEN|pair_loot|TM|0.8|MeasureStringY
ZEDQA pnow CEN|pair_loot|TM|21.7|getFontHeight
ZEDQA pnow NOTE card item JS-2000 Shotgun
ZEDQA pnow FRAME|card|frames=600|avgMs=15.910|p95=22.0|worst=33
ZEDQA pnow PROF|card|frames=600|frameMs=15.62|sumPreRender=8.48
ZEDQA pnow PROF|card|4.538 ms/frame|1.85 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|card|1.263 ms/frame|0.92 calls/frame|ZeD_ItemCard render 385x650 d2
ZEDQA pnow PROF|card|0.965 ms/frame|3.69 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|card|0.393 ms/frame|0.92 calls/frame|ZeD_Window prerender 1162x735 d0
ZEDQA pnow PROF|card|0.328 ms/frame|0.92 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|card|0.273 ms/frame|0.92 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|card|0.248 ms/frame|0.92 calls/frame|ZeD_WindowOverlay render 1162x735 d1
ZEDQA pnow PROF|card|0.225 ms/frame|1.85 calls/frame|ZeD_Panel prerender 385x650 d1
ZEDQA pnow PROF|card|0.115 ms/frame|1.85 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|card|0.048 ms/frame|0.14 calls/frame|ZeD_Window update 1162x735 d0
ZEDQA pnow PROF|card|0.038 ms/frame|1.85 calls/frame|ISPanel render 777x735 d1
ZEDQA pnow PROF|card|0.032 ms/frame|0.14 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|card|0.023 ms/frame|0.92 calls/frame|ZeD_Window render 1162x735 d0
ZEDQA pnow PROF|card|0.018 ms/frame|0.92 calls/frame|ZeD_ItemCard prerender 385x650 d2
ZEDQA pnow CEN|card|frames=240|LEAN draw calls per frame=683.3|ISUIElement draw calls per frame=19.8|TM calls per frame=127.9
ZEDQA pnow CEN|card|LEAN|349.1|ZeD_Panel|drawRect 166.6, drawTextureScaled 83.3, drawText 67.4, drawTextureScaledAspect 28.8, drawRectBorder 3.0
ZEDQA pnow CEN|card|LEAN|112.1|ZeD_ItemCard|drawRect 79.3, drawText 25.8, drawTextureScaledAspect 4.0, drawRectBorder 3.0
ZEDQA pnow CEN|card|LEAN|111.1|ZeD_Window|drawRect 94.2, drawRectBorder 7.9, drawText 5.0, drawTextureScaledAspect 4.0
ZEDQA pnow CEN|card|LEAN|74.4|ZeD_WindowOverlay|drawRect 70.4, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|card|LEAN|34.7|ZeD_BeltHUD|drawTextureScaled 7.9, drawTextureScaledAspect 7.9, drawRect 7.9, drawRectBorder 6.0, drawText 5.0
ZEDQA pnow CEN|card|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|card|UIE|6.0|ZeD_Panel|setStencilRect 6.0
ZEDQA pnow CEN|card|UIE|5.0|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|card|UIE|3.0|WaterMarkUI|drawTextRight 3.0
ZEDQA pnow CEN|card|UIE|3.0|ZeD_MoodleLayer|drawTexture 3.0
ZEDQA pnow CEN|card|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|card|UIE|1.0|ZeD_ItemCard|setStencilRect 1.0
ZEDQA pnow CEN|card|TM|99.1|MeasureStringX
ZEDQA pnow CEN|card|TM|1.0|MeasureStringY
ZEDQA pnow CEN|card|TM|27.8|getFontHeight
ZEDQA pnow FRAME|maps|frames=600|avgMs=18.277|p95=23.0|worst=37
ZEDQA pnow PROF|maps|frames=600|frameMs=18.57|sumPreRender=10.69
ZEDQA pnow PROF|maps|5.125 ms/frame|1.99 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|maps|1.340 ms/frame|1.00 calls/frame|ZeD_Panel prerender 840x650 d1
ZEDQA pnow PROF|maps|1.275 ms/frame|1.00 calls/frame|ZeD_WorldMap render 840x456 d2
ZEDQA pnow PROF|maps|1.212 ms/frame|3.98 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|maps|0.452 ms/frame|1.00 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|maps|0.373 ms/frame|1.00 calls/frame|ZeD_Window prerender 1617x735 d0
ZEDQA pnow PROF|maps|0.327 ms/frame|1.00 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|maps|0.292 ms/frame|1.00 calls/frame|ZeD_WindowOverlay render 1617x735 d1
ZEDQA pnow PROF|maps|0.203 ms/frame|2.98 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|maps|0.047 ms/frame|0.17 calls/frame|ZeD_Window update 1617x735 d0
ZEDQA pnow PROF|maps|0.037 ms/frame|0.17 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|maps|0.030 ms/frame|1.99 calls/frame|ISPanel render 777x735 d1
ZEDQA pnow PROF|maps|0.022 ms/frame|1.00 calls/frame|ZeD_Window render 777x735 d0
ZEDQA pnow PROF|maps|0.015 ms/frame|1.99 calls/frame|ZeD_Panel render 651x650 d1
ZEDQA pnow CEN|maps|frames=240|LEAN draw calls per frame=778.0|ISUIElement draw calls per frame=51.0|TM calls per frame=125.0
ZEDQA pnow CEN|maps|LEAN|556.0|ZeD_Panel|drawRect 360.0, drawTextureScaled 84.0, drawText 73.0, drawTextureScaledAspect 36.0, drawRectBorder 3.0
ZEDQA pnow CEN|maps|LEAN|110.0|ZeD_Window|drawRect 93.0, drawRectBorder 8.0, drawText 5.0, drawTextureScaledAspect 4.0
ZEDQA pnow CEN|maps|LEAN|75.0|ZeD_WindowOverlay|drawRect 71.0, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|maps|LEAN|35.0|ZeD_BeltHUD|drawTextureScaled 8.0, drawTextureScaledAspect 8.0, drawRect 8.0, drawRectBorder 6.0, drawText 5.0
ZEDQA pnow CEN|maps|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|maps|UIE|32.0|ZeD_WorldMap|drawRect 26.0, drawText 3.0, drawRectBorder 2.0, setStencilRect 1.0
ZEDQA pnow CEN|maps|UIE|6.0|ZeD_Panel|setStencilRect 6.0
ZEDQA pnow CEN|maps|UIE|5.0|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|maps|UIE|3.0|ZeD_MoodleLayer|drawTexture 3.0
ZEDQA pnow CEN|maps|UIE|3.0|WaterMarkUI|drawTextRight 3.0
ZEDQA pnow CEN|maps|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|maps|TM|90.0|MeasureStringX
ZEDQA pnow CEN|maps|TM|1.0|MeasureStringY
ZEDQA pnow CEN|maps|TM|34.0|getFontHeight
ZEDQA pnow FRAME|craft|frames=600|avgMs=14.883|p95=21.0|worst=41
ZEDQA pnow PROF|craft|frames=600|frameMs=15.33|sumPreRender=8.25
ZEDQA pnow PROF|craft|4.372 ms/frame|1.78 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|craft|1.260 ms/frame|0.89 calls/frame|ZeD_Panel prerender 840x650 d1
ZEDQA pnow PROF|craft|0.918 ms/frame|3.57 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|craft|0.422 ms/frame|0.89 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|craft|0.355 ms/frame|0.89 calls/frame|ZeD_Window prerender 1617x735 d0
ZEDQA pnow PROF|craft|0.248 ms/frame|0.89 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|craft|0.247 ms/frame|0.89 calls/frame|ZeD_WindowOverlay render 1617x735 d1
ZEDQA pnow PROF|craft|0.180 ms/frame|2.68 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|craft|0.092 ms/frame|0.89 calls/frame|ISTextEntryBox prerender 224x46 d3
ZEDQA pnow PROF|craft|0.032 ms/frame|0.89 calls/frame|ZeD_SearchField prerender 266x46 d2
ZEDQA pnow PROF|craft|0.030 ms/frame|0.14 calls/frame|ZeD_Window update 1617x735 d0
ZEDQA pnow PROF|craft|0.030 ms/frame|0.14 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|craft|0.028 ms/frame|0.89 calls/frame|ZeD_SearchField render 266x46 d2
ZEDQA pnow PROF|craft|0.027 ms/frame|0.89 calls/frame|ZeD_Window render 1617x735 d0
ZEDQA pnow CEN|craft|frames=240|LEAN draw calls per frame=637.7|ISUIElement draw calls per frame=20.5|TM calls per frame=144.1
ZEDQA pnow CEN|craft|LEAN|400.7|ZeD_Panel|drawRect 205.7, drawTextureScaled 81.9, drawText 80.0, drawTextureScaledAspect 30.2, drawRectBorder 2.9
ZEDQA pnow CEN|craft|LEAN|113.1|ZeD_Window|drawRect 96.5, drawRectBorder 7.8, drawText 4.9, drawTextureScaledAspect 3.9
ZEDQA pnow CEN|craft|LEAN|73.1|ZeD_WindowOverlay|drawRect 69.2, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|craft|LEAN|34.1|ZeD_BeltHUD|drawTextureScaled 7.8, drawTextureScaledAspect 7.8, drawRect 7.8, drawRectBorder 5.8, drawText 4.9
ZEDQA pnow CEN|craft|LEAN|14.6|ZeD_SearchField|drawRect 13.6, drawRectBorder 1.0
ZEDQA pnow CEN|craft|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|craft|UIE|6.8|ZeD_Panel|setStencilRect 6.8
ZEDQA pnow CEN|craft|UIE|4.9|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|craft|UIE|2.9|WaterMarkUI|drawTextRight 2.9
ZEDQA pnow CEN|craft|UIE|2.9|ZeD_MoodleLayer|drawTexture 2.9
ZEDQA pnow CEN|craft|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|craft|UIE|1.0|ISTextEntryBox|drawText 1.0
ZEDQA pnow CEN|craft|TM|102.2|MeasureStringX
ZEDQA pnow CEN|craft|TM|1.0|MeasureStringY
ZEDQA pnow CEN|craft|TM|41.0|getFontHeight
ZEDQA pnow FRAME|health|frames=600|avgMs=18.845|p95=27.0|worst=36
ZEDQA pnow PROF|health|frames=600|frameMs=18.13|sumPreRender=10.96
ZEDQA pnow PROF|health|4.982 ms/frame|1.97 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|health|3.208 ms/frame|0.99 calls/frame|ZeD_Panel prerender 840x650 d1
ZEDQA pnow PROF|health|1.158 ms/frame|3.95 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|health|0.460 ms/frame|0.99 calls/frame|ZeD_Window prerender 1617x735 d0
ZEDQA pnow PROF|health|0.327 ms/frame|0.99 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|health|0.300 ms/frame|0.99 calls/frame|ZeD_WindowOverlay render 1617x735 d1
ZEDQA pnow PROF|health|0.280 ms/frame|0.99 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|health|0.155 ms/frame|2.96 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|health|0.047 ms/frame|0.17 calls/frame|ZeD_Window update 1617x735 d0
ZEDQA pnow PROF|health|0.040 ms/frame|0.17 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|health|0.030 ms/frame|1.97 calls/frame|ISPanel render 777x735 d1
ZEDQA pnow PROF|health|0.018 ms/frame|0.99 calls/frame|ZeD_Window render 777x735 d0
ZEDQA pnow PROF|health|0.017 ms/frame|0.99 calls/frame|ZeD_Window render 1617x735 d0
ZEDQA pnow PROF|health|0.015 ms/frame|1.97 calls/frame|ZeD_Panel render 651x650 d1
ZEDQA pnow CEN|health|frames=240|LEAN draw calls per frame=703.0|ISUIElement draw calls per frame=37.0|TM calls per frame=248.0
ZEDQA pnow CEN|health|LEAN|481.0|ZeD_Panel|drawRect 245.0, drawText 115.0, drawTextureScaled 86.0, drawTextureScaledAspect 29.0, drawRectBorder 6.0
ZEDQA pnow CEN|health|LEAN|110.0|ZeD_Window|drawRect 93.0, drawRectBorder 8.0, drawText 5.0, drawTextureScaledAspect 4.0
ZEDQA pnow CEN|health|LEAN|75.0|ZeD_WindowOverlay|drawRect 71.0, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|health|LEAN|35.0|ZeD_BeltHUD|drawTextureScaled 8.0, drawTextureScaledAspect 8.0, drawRect 8.0, drawRectBorder 6.0, drawText 5.0
ZEDQA pnow CEN|health|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|health|UIE|24.0|ZeD_Panel|drawTextureScaledUniform 17.0, setStencilRect 7.0
ZEDQA pnow CEN|health|UIE|5.0|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|health|UIE|3.0|WaterMarkUI|drawTextRight 3.0
ZEDQA pnow CEN|health|UIE|3.0|ZeD_MoodleLayer|drawTexture 3.0
ZEDQA pnow CEN|health|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|health|TM|118.0|MeasureStringX
ZEDQA pnow CEN|health|TM|1.0|MeasureStringY
ZEDQA pnow CEN|health|TM|129.0|getFontHeight
ZEDQA pnow FRAME|skills|frames=600|avgMs=18.783|p95=24.0|worst=37
ZEDQA pnow PROF|skills|frames=600|frameMs=19.34|sumPreRender=11.90
ZEDQA pnow PROF|skills|5.340 ms/frame|1.99 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|skills|3.598 ms/frame|1.00 calls/frame|ZeD_Panel prerender 840x650 d1
ZEDQA pnow PROF|skills|1.162 ms/frame|3.99 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|skills|0.447 ms/frame|1.00 calls/frame|ZeD_Window prerender 1617x735 d0
ZEDQA pnow PROF|skills|0.360 ms/frame|1.00 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|skills|0.317 ms/frame|1.00 calls/frame|ZeD_WindowOverlay render 1617x735 d1
ZEDQA pnow PROF|skills|0.270 ms/frame|1.00 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|skills|0.163 ms/frame|2.99 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|skills|0.072 ms/frame|1.00 calls/frame|ISTextEntryBox prerender 308x46 d3
ZEDQA pnow PROF|skills|0.055 ms/frame|0.18 calls/frame|ZeD_Window update 1617x735 d0
ZEDQA pnow PROF|skills|0.038 ms/frame|1.00 calls/frame|ZeD_TabFindField prerender 350x46 d2
ZEDQA pnow PROF|skills|0.035 ms/frame|0.18 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|skills|0.033 ms/frame|1.00 calls/frame|ZeD_Window render 1617x735 d0
ZEDQA pnow PROF|skills|0.030 ms/frame|1.00 calls/frame|ZeD_TabFindField render 350x46 d2
ZEDQA pnow CEN|skills|frames=240|LEAN draw calls per frame=747.0|ISUIElement draw calls per frame=21.0|TM calls per frame=189.0
ZEDQA pnow CEN|skills|LEAN|510.0|ZeD_Panel|drawRect 270.0, drawText 120.0, drawTextureScaled 84.0, drawTextureScaledAspect 29.0, drawRectBorder 7.0
ZEDQA pnow CEN|skills|LEAN|110.0|ZeD_Window|drawRect 93.0, drawRectBorder 8.0, drawText 5.0, drawTextureScaledAspect 4.0
ZEDQA pnow CEN|skills|LEAN|75.0|ZeD_WindowOverlay|drawRect 71.0, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|skills|LEAN|35.0|ZeD_BeltHUD|drawTextureScaled 8.0, drawTextureScaledAspect 8.0, drawRect 8.0, drawRectBorder 6.0, drawText 5.0
ZEDQA pnow CEN|skills|LEAN|15.0|ZeD_TabFindField|drawRect 14.0, drawRectBorder 1.0
ZEDQA pnow CEN|skills|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|skills|UIE|7.0|ZeD_Panel|setStencilRect 7.0
ZEDQA pnow CEN|skills|UIE|5.0|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|skills|UIE|3.0|WaterMarkUI|drawTextRight 3.0
ZEDQA pnow CEN|skills|UIE|3.0|ZeD_MoodleLayer|drawTexture 3.0
ZEDQA pnow CEN|skills|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|skills|UIE|1.0|ISTextEntryBox|drawText 1.0
ZEDQA pnow CEN|skills|TM|128.0|MeasureStringX
ZEDQA pnow CEN|skills|TM|1.0|MeasureStringY
ZEDQA pnow CEN|skills|TM|60.0|getFontHeight
ZEDQA pnow FRAME|equip|frames=600|avgMs=18.885|p95=25.0|worst=36
ZEDQA pnow PROF|equip|frames=600|frameMs=17.59|sumPreRender=10.77
ZEDQA pnow PROF|equip|4.797 ms/frame|1.97 calls/frame|ZeD_Panel prerender 651x650 d1
ZEDQA pnow PROF|equip|3.130 ms/frame|0.99 calls/frame|ZeD_Panel prerender 840x650 d1
ZEDQA pnow PROF|equip|1.055 ms/frame|3.95 calls/frame|ZeD_Panel prerender 63x650 d1
ZEDQA pnow PROF|equip|0.418 ms/frame|0.99 calls/frame|ZeD_Window prerender 1617x735 d0
ZEDQA pnow PROF|equip|0.330 ms/frame|0.99 calls/frame|ZeD_Window prerender 777x735 d0
ZEDQA pnow PROF|equip|0.315 ms/frame|0.99 calls/frame|ZeD_WindowOverlay render 777x735 d1
ZEDQA pnow PROF|equip|0.285 ms/frame|0.99 calls/frame|ZeD_WindowOverlay render 1617x735 d1
ZEDQA pnow PROF|equip|0.165 ms/frame|2.96 calls/frame|ZeD_Panel prerender 0x650 d1
ZEDQA pnow PROF|equip|0.067 ms/frame|0.99 calls/frame|ZeD_TabFindField prerender 350x46 d2
ZEDQA pnow PROF|equip|0.058 ms/frame|0.99 calls/frame|ISTextEntryBox prerender 308x46 d3
ZEDQA pnow PROF|equip|0.052 ms/frame|0.16 calls/frame|ZeD_Window update 777x735 d0
ZEDQA pnow PROF|equip|0.045 ms/frame|0.99 calls/frame|ZeD_TabFindField render 350x46 d2
ZEDQA pnow PROF|equip|0.035 ms/frame|0.16 calls/frame|ZeD_Window update 1617x735 d0
ZEDQA pnow PROF|equip|0.030 ms/frame|0.99 calls/frame|ZeD_Window render 1617x735 d0
ZEDQA pnow CEN|equip|frames=240|LEAN draw calls per frame=751.0|ISUIElement draw calls per frame=38.0|TM calls per frame=180.9
ZEDQA pnow CEN|equip|LEAN|513.0|ZeD_Panel|drawRect 265.0, drawText 117.0, drawTextureScaled 86.0, drawTextureScaledAspect 39.0, drawRectBorder 6.0
ZEDQA pnow CEN|equip|LEAN|111.0|ZeD_Window|drawRect 94.0, drawRectBorder 8.0, drawText 5.0, drawTextureScaledAspect 4.0
ZEDQA pnow CEN|equip|LEAN|75.0|ZeD_WindowOverlay|drawRect 71.0, drawText 2.0, drawRectBorder 2.0
ZEDQA pnow CEN|equip|LEAN|35.0|ZeD_BeltHUD|drawTextureScaled 8.0, drawTextureScaledAspect 8.0, drawRect 8.0, drawRectBorder 6.0, drawText 5.0
ZEDQA pnow CEN|equip|LEAN|15.0|ZeD_TabFindField|drawRect 14.0, drawRectBorder 1.0
ZEDQA pnow CEN|equip|LEAN|2.0|ZeD_Watch|drawTextureScaled 2.0
ZEDQA pnow CEN|equip|UIE|24.0|ZeD_Panel|drawTextureScaledUniform 17.0, setStencilRect 7.0
ZEDQA pnow CEN|equip|UIE|5.0|ISButton|drawTexture 1.0, drawTextureScaledAspect 1.0, drawRect 1.0, drawRectBorder 1.0, drawText 1.0
ZEDQA pnow CEN|equip|UIE|3.0|WaterMarkUI|drawTextRight 3.0
ZEDQA pnow CEN|equip|UIE|3.0|ZeD_MoodleLayer|drawTexture 3.0
ZEDQA pnow CEN|equip|UIE|2.0|ZeD_BeltHUD|setStencilRect 2.0
ZEDQA pnow CEN|equip|UIE|1.0|ISTextEntryBox|drawText 1.0
ZEDQA pnow CEN|equip|TM|108.9|MeasureStringX
ZEDQA pnow CEN|equip|TM|1.0|MeasureStringY
ZEDQA pnow CEN|equip|TM|71.0|getFontHeight
ZEDQA pnow END char=loot world=loot
ZEDQA pnow DONE
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
