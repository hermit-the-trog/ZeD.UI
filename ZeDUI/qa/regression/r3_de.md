# ZeD-UI regression - 2026-11-12 16:34 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 16:34:41 |
| Finished | 2026-11-12 16:41:05 (6 min 24 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\zedqa_animals_quick.txt (2 scripts) |
| Result | **0/2 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 25746 to 25749 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 25748, 25749)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_animals_quick.lua | aq | WARN | 131 | zqa_aq_1_greyed.png, zqa_aq_2_live.png, zqa_aq_3_milking.png, zqa_aq_4_hungry.png, zqa_aq_5_ram_ticked.png, zqa_aq_6_shearing.png, zqa_aq_7_done.png, zqa_aq_8_milking_run.png, zqa_aq_8a_dry.png, zqa_aq_8b_feed_greyed.png, zqa_aq_8c_feed_picker.png, zqa_aq_8d_feeding.png, zqa_aq_9_pad_band.png, zqa_aq_10_pad_alerts.png | 8 ERR line(s) |
| 2 | zedqa_animals_quick_more.lua | aq2 | WARN | 150 | zqa_aq2_1_band_normal.png, zqa_aq2_2_hover_why.png, zqa_aq2_3_pad_why.png, zqa_aq2_4_pad_after_milkable.png, zqa_aq2_5_pad_run.png, zqa_aq2_6_after_walk_away.png, zqa_aq2_7_band_large.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_animals_quick.lua (`ZEDQA aq`) - WARN, 131 s

- go 25746 at 16:35:52
- 8 ERR line(s)
- screenshots: zqa_aq_1_greyed.png, zqa_aq_2_live.png, zqa_aq_3_milking.png, zqa_aq_4_hungry.png, zqa_aq_5_ram_ticked.png, zqa_aq_6_shearing.png, zqa_aq_7_done.png, zqa_aq_8_milking_run.png, zqa_aq_8a_dry.png, zqa_aq_8b_feed_greyed.png, zqa_aq_8c_feed_picker.png, zqa_aq_8d_feeding.png, zqa_aq_9_pad_band.png, zqa_aq_10_pad_alerts.png

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=30 missing=get
[ZeD.QA] windows reset (R)
ZEDQA aq start
[ZeD.QA] run #1 ok=true
ZEDQA aq made a cow at 929,13041
ZEDQA aq made a ram at 922,13042
ZEDQA aq made a cow at 928,13037
ZEDQA aq ram: canBeSheared true, canBeMilked false, wool 4.67657470703125 of 4.67657470703125
ZEDQA aq set aside: 3 milk containers, 5 cow foods, shears; zone ok=true
ZEDQA aq PASS the milk cow's alert offers Milk | milk
ZEDQA aq PASS Milk greyed: the milk-container reason | Melken braucht einen leeren Behälter oder einen mit dieser Milch, nicht in einer Tasche.
ZEDQA aq PASS the ram's alert offers Shear | shear
ZEDQA aq PASS Shear greyed: needs shears | Scheren braucht eine Schafschere.
ZEDQA aq PASS the starving cow's alert offers Walk to, live | goto
ZEDQA aq PASS with a bucket, Milk is live
ZEDQA aq PASS with shears, Shear is live
ZEDQA aq PASS Walk to pressed
ZEDQA aq queue after Walk to: ISWalkToTimedAction
ZEDQA aq PASS the game's walk is queued
ZEDQA aq waited for the walk
ZEDQA aq PASS Milk pressed on the alert
ZEDQA aq queue after Milk: ISWalkToTimedActionF,ISMilkAnimal
ZEDQA aq PASS ISMilkAnimal is queued after the walk to its side (or the walk up comes first)
ZEDQA aq waited for the milking
ZEDQA aq the alert's milking ended: Fertig: 1 von 1. | cause done | walked up first false | 0.3 squares off, stress 0
ZEDQA aq PASS the cow gave milk | 6.00 -> 0.00
ZEDQA aq made a cow at 894,13041
ZEDQA aq the far cow: body points known false
ZEDQA aq far milk pressed: true nil; queue ISWalkToTimedAction
ZEDQA aq PASS far: the milking run starts
ZEDQA aq PASS far: with no body points only the walk up is handed over (no ISMilkAnimal yet) | ISWalkToTimedAction
ZEDQA aq waited for the far milking
ZEDQA aq the far milking ended: Gestoppt nach 0 von 1. | cause cut | walked up first true | 6.1 squares off, stress 0
ZEDQA aq FAIL far: walked up and milked | 6.00 -> 6.00
ZEDQA aq made a cow at 904,13044
ZEDQA aq the cow off its square: square nil; can milk false Dieses Tier ist außer Reichweite.
ZEDQA aq PASS out of reach: a cow with no square says so | Dieses Tier ist außer Reichweite.
ZEDQA aq PASS out of reach: no run, nothing queued | Dieses Tier ist außer Reichweite.
ZEDQA aq before the zone view: milk in zone true at 929,13041 milk 0.0 wool 0.0 hunger 0; wool in zone true at 922,13042 milk 0.0 wool 4.7 hunger 0; hungry in zone true at 928,13037 milk 0.0 wool 0.0 hunger 90
ZEDQA aq waited for hungry live in the band
ZEDQA aq PASS All hungry is live (a starving cow)
ZEDQA aq PASS All hungry ticks the starving cow only
ZEDQA aq PASS with ticks the band offers Clear
ZEDQA aq waited for the ram's row in view
ZEDQA aq roster rows drawn: 1=milk cow, 2=ram; the ram in the zone's list: 1
ZEDQA aq PASS a roster row's stop has X
ZEDQA aq FAIL X ticked the ram
ZEDQA aq FAIL the band offers Shear (1) for the ticked ram
ZEDQA aq FAIL Shear started a run
ZEDQA aq FAIL during the run the band offers Stop
ZEDQA aq waited for the shearing run
ZEDQA aq the shearing ended: Gestoppt nach 0 von 1. | cause cut | walked up first true | 3.6 squares off, stress 0
ZEDQA aq FAIL the run ended Done 1 of 1 | Gestoppt nach 0 von 1.
ZEDQA aq FAIL the ram is shorn | 4.67657470703125
ZEDQA aq waited for milkable live in the band
ZEDQA aq before All milkable: milk in zone true at 929,13040 milk 4.0 wool 0.0 hunger 0; wool in zone true at 922,13042 milk 0.0 wool 4.7 hunger 0; hungry in zone true at 928,13037 milk 0.0 wool 0.0 hunger 90
ZEDQA aq PASS All milkable then Milk (n) is live | false
ZEDQA aq the band's milking (when it is over already) ended: nil | cause nil | walked up first true | 0.4 squares off, stress 0
ZEDQA aq PASS a milking run is going | Melke 1 von 1
ZEDQA aq PASS Stop ends it | Gestoppt nach 0 von 1.
ZEDQA aq PASS Stop leaves nothing queued |
ZEDQA aq PASS with 3 L in her, the cow has a milk alert
ZEDQA aq PASS with 5 wool on him, the ram has a shear alert
ZEDQA aq PASS All milkable counts the cow with milk
ZEDQA aq PASS milked dry: no milk alert | 0
ZEDQA aq PASS shorn: no shear alert | 0.5
ZEDQA aq PASS the Ranch page lists neither row
ZEDQA aq PASS All milkable counts nothing: it agrees with the alerts
ZEDQA aq PASS Feed (1) is in the band, greyed with no food carried
ZEDQA aq PASS with carrots carried (one in a bag), Feed is live
ZEDQA aq picker rows: Karotten [Für 1 von 1 | 2 dabei]
ZEDQA aq PASS the picker opens with one food (the steak is no cow food) | 1
ZEDQA aq PASS Carrots: for 1 of 1, 2 carried | Karotten Für 1 von 1 | 2 dabei
ZEDQA aq PASS picking Carrots started a feeding run | Füttere 1 von 1
ZEDQA aq queue after the pick: ISWalkToTimedAction,ISWalkToTimedActionF,ISEquipWeaponAction,ISFeedAnimalFromHand
ZEDQA aq waited for the feeding run
ZEDQA aq PASS the run ended Done 1 of 1 | Fertig: 1 von 1.
ZEDQA aq PASS the cow ate | 0.90 -> 0.82
ZEDQA aq PASS B on the picker closes it, nothing fed
ZEDQA aq waited for milkable live in the band
ZEDQA aq PASS the pad's focus is on All milkable | animals:bulk:milkable
ZEDQA aq PASS All milkable is a ring stop with A
ZEDQA aq PASS A on All milkable: the band turned to Clear
ZEDQA aq PASS A on All milkable: the focus lands on Clear, which took its place | animals:bulk:clear
ZEDQA aq FAIL the alert rows are stops with A
ZEDQA aq restored (the end): given and taken back 5, set aside and given back 9 of 9, animals removed 5 of 5, zones removed 1
ZEDQA aq PASS put back: nothing queued, the ledger spent
ZEDQA aq fails 8
ZEDQA aq DONE
```

### 2. zedqa_animals_quick_more.lua (`ZEDQA aq2`) - WARN, 150 s

- go 25747 at 16:38:07
- 1 ERR line(s)
- screenshots: zqa_aq2_1_band_normal.png, zqa_aq2_2_hover_why.png, zqa_aq2_3_pad_why.png, zqa_aq2_4_pad_after_milkable.png, zqa_aq2_5_pad_run.png, zqa_aq2_6_after_walk_away.png, zqa_aq2_7_band_large.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=30 missing=get
[ZeD.QA] windows reset (R)
ZEDQA aq2 start
[ZeD.QA] run #2 ok=true
ZEDQA aq2 made a cow at 912,13042
ZEDQA aq2 made a cow at 913,13038
ZEDQA aq2 made a ram at 906,13042
ZEDQA aq2 made a cow at 905,13037
ZEDQA aq2 milk containers set aside: 3
ZEDQA aq2 animals truetruetruetrue zone ok=true
ZEDQA aq2 band (zone view, nothing ticked, normal text): hungry 7,595 207x46; milkable 221,595 207x46; rename 455,595 162x46; remove 625,595 207x46; window width 1617
ZEDQA aq2 PASS f zone view, nothing ticked, normal text: All hungry, All milkable, Rename and Remove zone are all in the band | hungry,milkable,rename,remove
ZEDQA aq2 PASS f zone view, nothing ticked, normal text: they sit in one row, apart, inside the window
ZEDQA aq2 PASS b with two milk cows ticked and no bucket, Milk (2) is greyed | true
ZEDQA aq2 PASS b the pointer on greyed Milk: the balloon asks to show 'Melken braucht einen leeren Behälter oder einen mit dieser Milch, nicht in einer Tasche.' | Melken braucht einen leeren Behälter oder einen mit dieser Milch, nicht in einer Tasche.
ZEDQA aq2 PASS b the pad's focus is on greyed Milk | animals:bulk:milk
ZEDQA aq2 PASS b the pad's focus on greyed Milk: the balloon asks at once with the reason | Melken braucht einen leeren Behälter oder einen mit dieser Milch, nicht in einer Tasche.
ZEDQA aq2 PASS b the greyed button is still a stop (A on it does nothing)
ZEDQA aq2 PASS b A on the greyed Milk starts nothing
ZEDQA aq2 PASS c with ticks, Clear is a stop
ZEDQA aq2 PASS c A on Clear: the focus lands on All hungry, which takes its place | animals:bulk:hungry
ZEDQA aq2 PASS c A on All milkable: the focus lands on Clear | animals:bulk:clear
ZEDQA aq2 PASS c with a bucket, Milk (2) is live | false nil
ZEDQA aq2 PASS c A on Milk (2) starts the run | Melke 1 von 2
ZEDQA aq2 PASS c A on Milk: the focus lands on Stop, which takes its place | animals:bulk:stop
ZEDQA aq2 waited for the two-cow milking run
ZEDQA aq2 PASS d the run reached the second cow
ZEDQA aq2 PASS d the second cow was handed over only when the first was done (done 1, first cow still has milk: false)
ZEDQA aq2 PASS d never two milkings queued at once
ZEDQA aq2 d the run ended: Fertig: 2 von 2. | cause done
ZEDQA aq2 PASS d the run ended Done 2 of 2 | Fertig: 2 von 2.
ZEDQA aq2 PASS d nothing left in the queue |
ZEDQA aq2 gave up waiting for the milking to start
ZEDQA aq2 walking away from: / nil
ZEDQA aq2 waited for the run to stop after the walk
ZEDQA aq2 PASS e walking away: the run is over
ZEDQA aq2 PASS e it says how it ended | Fertig: 2 von 2.
ZEDQA aq2 FAIL e it ended because the player was moved off | done
ZEDQA aq2 PASS e nothing is left queued or running |
ZEDQA aq2 animal c1 blockMovement false
ZEDQA aq2 animal c2 blockMovement false
ZEDQA aq2 animal ewe blockMovement false
ZEDQA aq2 animal hungry blockMovement false
ZEDQA aq2 PASS e no animal is held still |
ZEDQA aq2 band (zone view, normal text, again): hungry 7,595 207x46; milkable 221,595 207x46; rename 455,595 162x46; remove 625,595 207x46; window width 1617
ZEDQA aq2 PASS f zone view, normal text, again: All hungry, All milkable, Rename and Remove zone are all in the band | hungry,milkable,rename,remove
ZEDQA aq2 PASS f zone view, normal text, again: they sit in one row, apart, inside the window
ZEDQA aq2 PASS f the text size option is there
ZEDQA aq2 text size now large
ZEDQA aq2 band (zone view, Large text): hungry 8,575 242x53; milkable 258,575 242x53; rename 518,575 188x53; remove 715,575 242x53; window width 1743
ZEDQA aq2 PASS f zone view, Large text: All hungry, All milkable, Rename and Remove zone are all in the band | hungry,milkable,rename,remove
ZEDQA aq2 PASS f zone view, Large text: they sit in one row, apart, inside the window
ZEDQA aq2 restored (the end): given and taken back 2, set aside and given back 4 of 4, animals removed 4 of 4, zones removed 1
ZEDQA aq2 fails 1
ZEDQA aq2 DONE
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
