# ZeD-UI regression - 2026-11-06 22:09 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 22:09:21 |
| Finished | 2026-11-06 22:11:00 (1 min 39 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\ranch_long.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 22726 to 22730 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22729, 22730)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_ranch_long.lua | rlg | PASS | 12 | zqa_rlg_01_after_down.png, zqa_rlg_02_foot.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22726 at 22:10:15

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=36 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 4.05 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22727 at 22:10:21

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=36 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_ranch_long.lua (`ZEDQA rlg`) - PASS, 12 s

- go 22728 at 22:10:25
- screenshots: zqa_rlg_01_after_down.png, zqa_rlg_02_foot.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=36 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rlg start
[ZeD.QA] run #3 ok=true
ZEDQA rlg player 925,13040,0
ZEDQA rlg no sprite name at 914,13034 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@958278f item Base.CarKey:zombie.inventory.types.Key@546b954
ZEDQA rlg no sprite name at 915,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@66f19b9e item Base.CarKey:zombie.inventory.types.Key@67636178
ZEDQA rlg no sprite name at 917,13046 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2fcf5644 item Base.CarKey:zombie.inventory.types.Key@1f73d6f0
ZEDQA rlg no sprite name at 917,13051 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@75b483eb item Base.CarKey:zombie.inventory.types.Key@9a04484
ZEDQA rlg no sprite name at 920,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@5c084e82 item Base.CarKey:zombie.inventory.types.Key@5dcdc7a5
ZEDQA rlg no sprite name at 920,13036 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@cb7ac2c item Base.CarKey:zombie.inventory.types.Key@7384d5a
ZEDQA rlg no sprite name at 920,13047 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@19da6f61 item Base.CarKey:zombie.inventory.types.Key@2a996310
ZEDQA rlg no sprite name at 920,13047 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@1bfe7ca3 item Base.Egg:zombie.inventory.types.Food@5e69a01b
ZEDQA rlg no sprite name at 921,13043 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@14826dd0 item Base.CarKey:zombie.inventory.types.Key@75e20db3
ZEDQA rlg no sprite name at 922,13046 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@1d916cc8 item Base.CarKey:zombie.inventory.types.Key@eeb6e19
ZEDQA rlg no sprite name at 924,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@9007ef9 item Base.CarKey:zombie.inventory.types.Key@6c6a75ff
ZEDQA rlg no sprite name at 924,13033 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@7a8ba396 item Base.Dung_Chicken:zombie.inventory.types.Food@2fc59178
ZEDQA rlg no sprite name at 924,13046 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@25b8c5cf item Base.CarKey:zombie.inventory.types.Key@1a42890a
ZEDQA rlg no sprite name at 924,13048 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@3df20ec7 item Base.Egg:zombie.inventory.types.Food@3e3f1650
ZEDQA rlg no sprite name at 924,13050 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@5d4a2ae5 item Base.CarKey:zombie.inventory.types.Key@534ef29f
ZEDQA rlg no sprite name at 925,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@7e674a07 item Base.ChickenFeather:zombie.inventory.types.Food@38ac4e0d
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@34bd46ff item Base.Splinters:zombie.inventory.types.ComboItem@3532a1dc
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@104380fd item Base.Nails:zombie.inventory.types.ComboItem@24574b5c
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@54b0d780 item Base.Nails:zombie.inventory.types.ComboItem@69626abc
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@eb6273d item Base.Nails:zombie.inventory.types.ComboItem@62ba2f82
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@506202aa item Base.Nails:zombie.inventory.types.ComboItem@42a65e48
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@5caa3433 item Base.Nails:zombie.inventory.types.ComboItem@5cb5f0eb
ZEDQA rlg no sprite name at 925,13040 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@e74e4f1 item Base.ChickenFeather:zombie.inventory.types.Food@2678464b
ZEDQA rlg no sprite name at 925,13048 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@31c4b5cd item Base.KeyRing:zombie.inventory.types.InventoryContainer@7173860d
ZEDQA rlg no sprite name at 926,13029 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@7c752fbc item Base.Egg:zombie.inventory.types.Food@550f1faf
ZEDQA rlg no sprite name at 926,13033 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@41f1a21e item Base.CarKey:zombie.inventory.types.Key@2c5f17c3
ZEDQA rlg no sprite name at 926,13035 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@7982d53b item Base.ChickenFeather:zombie.inventory.types.Food@545d5fc3
ZEDQA rlg no sprite name at 926,13041 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@18f0f604 item Base.Nails:zombie.inventory.types.ComboItem@150dab39
ZEDQA rlg no sprite name at 926,13041 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@4cc50bd6 item Base.Nails:zombie.inventory.types.ComboItem@6529e3ce
ZEDQA rlg no sprite name at 926,13043 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@23012478 item Base.CarKey:zombie.inventory.types.Key@1d9cd49c
ZEDQA rlg no sprite name at 926,13044 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2c351fd item Base.CarKey:zombie.inventory.types.Key@663c61c8
ZEDQA rlg no sprite name at 926,13046 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@4cb4bb93 item Base.CarKey:zombie.inventory.types.Key@37f7bead
ZEDQA rlg no sprite name at 927,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2f234d17 item Base.Egg:zombie.inventory.types.Food@2a144b1a
ZEDQA rlg no sprite name at 927,13039 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@439515e8 item Base.CarKey:zombie.inventory.types.Key@491dc9e1
ZEDQA rlg no sprite name at 927,13042 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@7ce36e20 item Base.CarKey:zombie.inventory.types.Key@74a7b63d
ZEDQA rlg no sprite name at 929,13034 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@1f76d714 item Base.Dung_Cow:zombie.inventory.types.Food@380357da
ZEDQA rlg no sprite name at 929,13041 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@5ff6bc94 item Base.CarKey:zombie.inventory.types.Key@16a9ef09
ZEDQA rlg no sprite name at 929,13045 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@3f4e44bf item Base.CarKey:zombie.inventory.types.Key@1d51690b
ZEDQA rlg no sprite name at 930,13039 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@77296429 item Base.ChickenFeather:zombie.inventory.types.Food@2e211c62
ZEDQA rlg no sprite name at 930,13050 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@6387dea5 item Base.CarKey:zombie.inventory.types.Key@7508faef
ZEDQA rlg no sprite name at 931,13032 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@493cc04b item Base.CarKey:zombie.inventory.types.Key@6f581702
ZEDQA rlg no sprite name at 931,13035 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@32779eba item Base.CarKey:zombie.inventory.types.Key@1ac599
ZEDQA rlg no sprite name at 931,13037 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2f0b7349 item Base.CarKey:zombie.inventory.types.Key@4481ad
ZEDQA rlg no sprite name at 932,13037 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@e484d51 item Base.CarKey:zombie.inventory.types.Key@5828670c
ZEDQA rlg no sprite name at 932,13037 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2c4dd67b item Base.CarKey:zombie.inventory.types.Key@82073b6
ZEDQA rlg no sprite name at 933,13043 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@44ce9526 item Base.CarKey:zombie.inventory.types.Key@5f459ab4
ZEDQA rlg no sprite name at 933,13047 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@1df96129 item Base.CarKey:zombie.inventory.types.Key@164f1ce3
ZEDQA rlg no sprite name at 934,13043 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@2698dca9 item Base.CarKey:zombie.inventory.types.Key@557b62f4
ZEDQA rlg no sprite name at 934,13043 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@35da15b item Base.Egg:zombie.inventory.types.Food@6d9b0dd7
ZEDQA rlg no sprite name at 934,13047 class WorldInventoryItem sprite zombie.iso.sprite.IsoSprite@d86e959 item Base.Egg:zombie.inventory.types.Food@3e446df
ZEDQA rlg scanned 740 objects, 50 with no sprite name
ZEDQA rlg animals 26, zones 1, alerts 44
ZEDQA rlg zone worldTabContent stops 50
ZEDQA rlg first animals:submode:ranch bar visible true range 2670.44140625
ZEDQA rlg Down stopped after 52 presses on animals:createzone now in worldTabContent, scroll 1
ZEDQA rlg wheel: 43 ticks to the foot, scroll 1 page range 2670.44140625
ZEDQA rlg DONE
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
