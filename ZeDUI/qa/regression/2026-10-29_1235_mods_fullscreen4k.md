# ZeD-UI regression - 2026-10-29 12:35 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 12:35:08 |
| Finished | 2026-10-29 12:39:15 (4 min 6 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/traits_manifest.txt (3 scripts) |
| Result | **2/3 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 15712 to 15716 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15715, 15716)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_traits.lua | tas | PASS | 26 | zqa_tas_tab.png, zqa_tas_details.png, zqa_tas_step_hover.png, zqa_tas_with_trait.png, zqa_tas_folded.png, zqa_tas_find.png, zqa_tas_pad_row.png, zqa_tas_new.png, zqa_tas_large.png, zqa_tas_light.png |  |
| 3 | zedqa_hairbeard.lua | hb | WARN | 92 | zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_mod_rows.png, zqa_hb_spongie_tag.png, zqa_hb_female_heads.png, zqa_hb_female_list.png | 9 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 15712 at 12:36:34

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 869,13025,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:310 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:312 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_traits.lua (`ZEDQA tas`) - PASS, 26 s

- go 15713 at 12:36:43
- screenshots: zqa_tas_tab.png, zqa_tas_details.png, zqa_tas_step_hover.png, zqa_tas_with_trait.png, zqa_tas_folded.png, zqa_tas_find.png, zqa_tas_pad_row.png, zqa_tas_new.png, zqa_tas_large.png, zqa_tas_light.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tas start
[ZeD.QA] run #2 ok=true
ZEDQA tas tabs: loot,equip,health,thermal,identity,journal,skills,traits,radio
ZEDQA tas PASS the Traits tab sits right after Skills
ZEDQA tas PASS the Traits tab is on the strip
ZEDQA tas PASS it has the lit pixel-art icon
ZEDQA tas PASS the Character window is on Traits
ZEDQA tas PASS one row per ladder in the mod's registry: 42 / 42
ZEDQA tas categories: inteligencia,physical,behavior,social,skills
ZEDQA tas PASS Mind first
ZEDQA tas PASS Skills last
ZEDQA tas ladders with a trait now: 9
ZEDQA tas PASS the Find box shows in the heading
ZEDQA tas shot zqa_tas_tab.png
ZEDQA tas PASS a row has a click zone
ZEDQA tas PASS a click picks the row for the details: TAS.Courage
ZEDQA tas shot zqa_tas_details.png
ZEDQA tas PASS hovering a step names its trait and level
ZEDQA tas shot zqa_tas_step_hover.png
ZEDQA tas PASS With a trait
ZEDQA tas PASS only ladders that give a trait are listed
ZEDQA tas shot zqa_tas_with_trait.png
ZEDQA tas PASS All again
ZEDQA tas PASS a click folds the category
ZEDQA tas shot zqa_tas_folded.png
ZEDQA tas PASS Find takes the typed text: read
ZEDQA tas PASS Find narrows the list (1 rows)
ZEDQA tas shot zqa_tas_find.png
ZEDQA tas PASS focus on the Traits tab in the strip
ZEDQA tas into the tab from the strip: tas:row:TAS.Vision
ZEDQA tas PASS the D-pad goes into the tab
ZEDQA tas PASS Find is a stop
ZEDQA tas PASS down from Find: All | With a trait (tas:only)
ZEDQA tas PASS right picks With a trait
ZEDQA tas PASS left picks All
ZEDQA tas PASS down: the first category (tas:cat:inteligencia)
ZEDQA tas PASS A folds the category
ZEDQA tas PASS down: a row (tas:row:TAS.Courage)
ZEDQA tas PASS the details follow focus with no press
ZEDQA tas PASS walking rows moves the details: tas:row:TAS.Learning
ZEDQA tas PASS A on a row does nothing
ZEDQA tas shot zqa_tas_pad_row.png
ZEDQA tas addXP Reading: true true
ZEDQA tas Reading now level 10, traits FAST_READER
ZEDQA tas PASS a trait gained since the last visit carries NEW
ZEDQA tas shot zqa_tas_new.png
ZEDQA tas shot zqa_tas_large.png
ZEDQA tas shot zqa_tas_light.png
ZEDQA tas all checks passed
ZEDQA tas DONE
```

### 3. zedqa_hairbeard.lua (`ZEDQA hb`) - WARN, 92 s

- go 15714 at 12:37:12
- 9 ERR line(s)
- screenshots: zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_mod_rows.png, zqa_hb_spongie_tag.png, zqa_hb_female_heads.png, zqa_hb_female_list.png

```text
[ZeD.QA] windows reset (R)
ZEDQA hb start
[ZeD.QA] run #3 ok=true
ZEDQA hb tools taken away for the test: 0 | female false | was Grungey /
ZEDQA hb PASS the Character window is on Identity
ZEDQA hb PASS hair rows from the game's menu: 38
ZEDQA hb groups: tie 1 shave 1 cut 29 style 7
ZEDQA hb PASS Tie and Cut groups
ZEDQA hb PASS a cut with no scissors is greyed with the game's reason: Requires Scissors.
ZEDQA hb PASS tying needs no tool
ZEDQA hb PASS a style with no gel or spray is greyed: Requires Hair Spray.
ZEDQA hb PASS no debug rows
ZEDQA hb Out of reach with Spongie's Hairstyle Unlocker on: 0 (every style at or under the length can be picked)
ZEDQA hb PASS the windows are still
ZEDQA hb figures no tools: 1 rows in view, 2 figures showing, pool 2
ZEDQA hb PASS every hair row in view shows its figure, and Now
ZEDQA hb figures the list: 1 rows in view, 1 figures showing, pool 2
ZEDQA hb PASS the list scrolled: every row in view shows its figure
ZEDQA hb shot zqa_hb_list_no_tools.png
ZEDQA hb rect list_no_tools list 357 111 815 521
ZEDQA hb rect list_no_tools heads 375 -121 779 157
ZEDQA hb PASS no drawn heads and no Pictures window left in the section
ZEDQA hb PASS the figures are a stand-in, not the player's own model
ZEDQA hb PASS a row's figure wears that row's style: PonyTail -> false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|1358744395|103246260|2114309842|1202646939|547541912|1774172218|1490752081|2010921844|1687152438|1025320574#PonyTail/Full
ZEDQA hb shot zqa_hb_no_tools.png
ZEDQA hb rect no_tools list 357 111 815 521
ZEDQA hb rect no_tools heads 375 181 779 157
ZEDQA hb figures Out of reach open: 1 rows in view, 1 figures showing, pool 2
ZEDQA hb PASS figures with Out of reach open
ZEDQA hb perf list: mean 8.8 ms, 95th 15 ms, worst 35 ms over 240 frames
ZEDQA hb PASS frame time sampled with the list open
ZEDQA hb PASS the tall window is still
ZEDQA hb figures tall window: 1 rows in view, 2 figures showing, pool 2
ZEDQA hb PASS the tall window: every row in view with its figure
ZEDQA hb shot zqa_hb_tall.png
ZEDQA hb rect tall list 357 111 840 1886
ZEDQA hb rect tall heads 375 809 779 157
ZEDQA hb perf list_tall: mean 13.0 ms, 95th 19 ms, worst 41 ms over 240 frames
ZEDQA hb PASS frame time sampled with the tall window
ZEDQA hb perf tall window: 2 figures showing
ZEDQA hb PASS the window back to its height
ZEDQA hb PASS the real character is unchanged while the figures show (Fabian|Full|nil|1358744395|103246260|2114309842|1202646939|547541912|1774172218|1490752081|2010921844|1687152438|1025320574)
ZEDQA hb tab for the release check: loot
ZEDQA hb PASS another tab: the figures leave the window (pool 0, children 0)
ZEDQA hb perf other_tab: mean 8.4 ms, 95th 15 ms, worst 18 ms over 240 frames
ZEDQA hb PASS frame time sampled on another tab
ZEDQA hb perf the figures cost 0.3 ms a frame on the mean (list 8.8, other tab 8.4)
ZEDQA hb perf tall window costs 4.6 ms a frame on the mean (13.0)
ZEDQA hb figures back on Identity: 1 rows in view, 2 figures showing, pool 2
ZEDQA hb PASS back on Identity, the figures come back
ZEDQA hb FAIL the cut row has a click zone
ZEDQA hb PASS the strip's button is greyed for a greyed row
ZEDQA hb PASS pressing the greyed button does nothing
ZEDQA hb FAIL the mouse is over a row (its hint shows)
ZEDQA hb shot zqa_hb_greyed_hover.png
ZEDQA hb PASS with scissors the cut can be done: Cut Hair into Short
ZEDQA hb head item: Baseball Cap
ZEDQA hb figures scissors and a cap: 4 rows in view, 6 figures showing, pool 6
ZEDQA hb figures scissors and a cap: 1 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS every row in view with its figure, and the Now / After heads
ZEDQA hb PASS the After head wears the picked style: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|1358744395|103246260|1619963885|2114309842|1202646939|547541912|1774172218|1490752081|2010921844|1687152438|1025320574#Short/Full
ZEDQA hb PASS the Now head wears the hair now: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|1358744395|103246260|1619963885|2114309842|1202646939|547541912|1774172218|1490752081|2010921844|1687152438|1025320574#Fabian/Full
ZEDQA hb PASS the cap is still on the real character (only the figures go without it)
ZEDQA hb PASS the heads half out of the view: Now and After show the part inside it
ZEDQA hb PASS hair: Now and After cut by the view's edge, not left empty (cut 64.4375 px)
ZEDQA hb shot zqa_hb_heads_cut.png
ZEDQA hb rect heads_cut list 357 111 815 473
ZEDQA hb rect heads_cut heads 375 45 779 157
ZEDQA hb shot zqa_hb_ready.png
ZEDQA hb rect ready list 357 111 815 473
ZEDQA hb rect ready heads 375 181 779 157
ZEDQA hb figures with scissors: 4 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS with scissors, the list: every row in view with its figure
ZEDQA hb shot zqa_hb_hair_list.png
ZEDQA hb rect hair_list list 357 111 815 473
ZEDQA hb rect hair_list heads 375 -121 779 157
ZEDQA hb PASS the strip's button is live
ZEDQA hb PASS the cut is running
ZEDQA hb PASS the game's ISCutHair is queued
ZEDQA hb shot zqa_hb_cutting.png
ZEDQA hb PASS the cut ends
ZEDQA hb PASS the hair is now Short: Short
ZEDQA hb PASS the strip says done: Done: hair is now Short
ZEDQA hb PASS the cap came off first
ZEDQA hb PASS the license's Hair style line follows: Short
ZEDQA hb shot zqa_hb_done.png
ZEDQA hb PASS a tie row after growing it back
ZEDQA hb PASS the tie row is a controller stop
ZEDQA hb PASS the tie ends
ZEDQA hb PASS tied: the loose style is kept (Fabian)
ZEDQA hb PASS tied: Untie Hair is the only row (1)
ZEDQA hb shot zqa_hb_tied.png
ZEDQA hb PASS the untie ends
ZEDQA hb PASS untied: back to Fabian (Fabian)
ZEDQA hb PASS focus on the tab's disclosure
ZEDQA hb PASS down from the disclosure lands on the Hair | Beard switch (hb:part)
ZEDQA hb PASS right flips to Beard and stays on the switch
ZEDQA hb FAIL down walks into the beard rows (hb:more)
ZEDQA hb FAIL the strip follows focus with no press
ZEDQA hb FAIL greyed with the game's reason: nil
ZEDQA hb PASS A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_greyed.png
ZEDQA hb PASS with scissors the trim can be done: Trim Beard into Mustache
ZEDQA hb figures beard: 3 rows in view, 6 figures showing, pool 6
ZEDQA hb figures beard: 1 rows in view, 4 figures showing, pool 6
ZEDQA hb PASS every beard row in view with its figure, and the Now / After heads
ZEDQA hb PASS the beard list runs on the character's own hair: Grungey
ZEDQA hb PASS beard, under the heads: every beard row's figure keeps the character's hair (Grungey, 1 rows)
ZEDQA hb PASS beard, under the heads: every beard row's figure wears that row's beard (1 rows)
ZEDQA hb PASS beard: Now shows the character as they are: #Grungey/Full@S
ZEDQA hb PASS the focused row is the picked one (b:Moustache)
ZEDQA hb PASS beard: After shows the picked row's result: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_pad_beard.png
ZEDQA hb rect pad_beard list 357 111 815 473
ZEDQA hb rect pad_beard heads 375 181 779 157
ZEDQA hb PASS beard: the heads half out of the view, Now and After show the part inside it
ZEDQA hb PASS beard: Now and After cut by the view's edge, not left empty
ZEDQA hb shot zqa_hb_beard_cut.png
ZEDQA hb rect beard_cut list 357 111 815 473
ZEDQA hb rect beard_cut heads 375 45 779 157
ZEDQA hb fig now y 111 h 66 cut 64 zoom 20.935 yoff -0.7730
ZEDQA hb fig b: y 316 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 438 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig after y 111 h 66 cut 64 zoom 20.935 yoff -0.7730
ZEDQA hb fig b:Moustache y 534 h 50 cut 21 zoom 20.467 yoff -0.8735
ZEDQA hb figures beard rows: 4 rows in view, 5 figures showing, pool 6
ZEDQA hb PASS beard: the list scrolled, every row in view with its figure
ZEDQA hb PASS beard, the list: every beard row's figure keeps the character's hair (Grungey, 4 rows)
ZEDQA hb PASS beard, the list: every beard row's figure wears that row's beard (4 rows)
ZEDQA hb PASS the picked beard row's figure wears that beard: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_beard_list.png
ZEDQA hb rect beard_list list 357 111 815 473
ZEDQA hb rect beard_list heads 375 -121 779 157
ZEDQA hb fig b:BeardOnly y 559 h 25 cut 46 zoom 22.724 yoff -0.9233
ZEDQA hb fig b: y 149 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 271 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Moustache y 367 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Goatee y 463 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb PASS the trim ends
ZEDQA hb PASS the beard is now Moustache: Moustache
ZEDQA hb FAIL Out of reach is a stop
ZEDQA hb FAIL A folds Out of reach open
ZEDQA hb PASS an out-of-reach row can be focused and says why
ZEDQA hb shot zqa_hb_out_of_reach.png
ZEDQA hb PASS a trait is a controller stop: identity:trait:Dextrous
ZEDQA hb FAIL focus shows the description at once (no hover timer)
ZEDQA hb shot zqa_hb_trait_focus.png
ZEDQA hb PASS trait zones are kept for hover
ZEDQA hb FAIL hover on a trait shows its description
ZEDQA hb shot zqa_hb_trait_hover.png
ZEDQA hb figures Large text: 1 rows in view, 2 figures showing, pool 6
ZEDQA hb PASS Large text: every row in view with its figure
ZEDQA hb shot zqa_hb_large.png
ZEDQA hb rect large list 240 127 938 491
ZEDQA hb rect large heads 260 -141 898 183
ZEDQA hb figures Light: 1 rows in view, 3 figures showing, pool 6
ZEDQA hb PASS Light: every row in view with its figure
ZEDQA hb shot zqa_hb_light.png
ZEDQA hb rect light list 357 111 815 521
ZEDQA hb rect light heads 375 -121 779 157
ZEDQA hb PASS Spongie's Hairstyle Unlocker: its extra rows carry its tag (Cut Hair into Fabian)
ZEDQA hb figures after Large and Light: 1 rows in view, 3 figures showing, pool 6
ZEDQA hb PASS every row in view with its figure
ZEDQA hb shot zqa_hb_mod_rows.png
ZEDQA hb rect mod_rows list 357 111 815 521
ZEDQA hb rect mod_rows heads 375 -121 779 157
ZEDQA hb PASS Spongie's tagged row in view with its figure
ZEDQA hb shot zqa_hb_spongie_tag.png
ZEDQA hb rect spongie_tag list 357 111 815 521
ZEDQA hb rect spongie_tag heads 375 -890 779 157
ZEDQA hb PASS the window closed: the figures left it (children 0)
ZEDQA hb figures reopened: 1 rows in view, 3 figures showing, pool 3
ZEDQA hb PASS reopened: the figures come back
ZEDQA hb made a woman for the check: true, skin FemaleBody03
ZEDQA hb figures a woman: 2 rows in view, 4 figures showing, pool 4
ZEDQA hb PASS a woman: her hair rows and Now show
ZEDQA hb PASS a woman: no beard half (0 beard rows)
ZEDQA hb PASS a woman: the figures' stand-in is a woman
ZEDQA hb PASS a woman: every row is one of the game's women's styles (44 rows)
ZEDQA hb PASS a woman: Now wears her hair: #Long2/
ZEDQA hb PASS a woman: After shows the picked cut
ZEDQA hb PASS a woman: After wears the picked cut: #Bob/
ZEDQA hb shot zqa_hb_female_heads.png
ZEDQA hb rect female_heads list 357 111 815 521
ZEDQA hb rect female_heads heads 375 181 779 157
ZEDQA hb figures a woman's list: 4 rows in view, 5 figures showing, pool 5
ZEDQA hb PASS a woman's list: every row in view with its figure
ZEDQA hb shot zqa_hb_female_list.png
ZEDQA hb rect female_list list 357 111 815 521
ZEDQA hb rect female_list heads 375 -121 779 157
ZEDQA hb PASS the QA character is put back: female false, skin MaleBody03
ZEDQA hb put back: Grungey / , 0 tools returned
ZEDQA hb 9 failed
ZEDQA hb DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
