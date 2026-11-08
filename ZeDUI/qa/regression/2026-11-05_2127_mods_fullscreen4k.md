# ZeD-UI regression - 2026-11-05 21:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 21:27:53 |
| Finished | 2026-11-05 21:33:09 (5 min 16 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\wheels_91.txt (7 scripts) |
| Result | **7/7 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21490 to 21498 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21497, 21498)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_dpad_wheels.lua | dw | PASS | 51 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 3 | zedqa_wheel_sizes.lua | ws | PASS | 16 | zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png |  |
| 4 | zedqa_wheel_icons.lua | wi | PASS | 59 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 5 | zedqa_wheels.lua | wh | PASS | 28 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |
| 6 | zedqa_pad_glyphs.lua | pg | PASS | 34 | zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png |  |
| 7 | zedqa_quick_chords.lua | qc | PASS | 25 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21490 at 21:28:50

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 51 s

- go 21491 at 21:28:55
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #2 ok=true
ZEDQA dw scene: at 925,13040, in a car false, health 100
ZEDQA dw foot left: 9 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid [>] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>] 9:Loadouts / No loadouts saved [off]
ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS left: the slice 'Tabs' is there
ZEDQA dw inner left: 10 slices, crumb Character + Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Cooking / Not now. [off] 6:Identity 7:Journal 8:Skills 9:Radio / No radio in your hands or on your back. [off] 10:Back
ZEDQA dw PASS left: the inner wheel ends with Back
ZEDQA dw PASS left: the breadcrumb names the inner wheel
ZEDQA dw PASS left: B from the inner wheel is back on the top level
ZEDQA dw PASS left: B on the top level closes the wheel
ZEDQA dw foot right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal / No tame animal in reach. [off] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS right: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS right: the slice 'Map' is there
ZEDQA dw inner right: 4 slices, crumb World + Map, visible true | 1:Show/Hide World Map 2:Show/Hide Mini-Map / The mini-map is off in this game. [off] 3:Focus Mini Map / The mini-map is off in this game. [off] 4:Back
ZEDQA dw PASS right: the inner wheel ends with Back
ZEDQA dw PASS right: the breadcrumb names the inner wheel
ZEDQA dw PASS right: B from the inner wheel is back on the top level
ZEDQA dw PASS right: B on the top level closes the wheel
ZEDQA dw foot up: 8 slices, crumb Social, visible false | 1:Friendly [>] 2:Hostile [>] 3:Group [>] 4:Signal [>] 5:Shout 6:Chat / On a server only. [off] 7:Safety / On a server only. [off] 8:Players / On a server only. [off]
ZEDQA dw PASS up: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS up: the slice 'Friendly' is there
ZEDQA dw inner up: 6 slices, crumb Social + Friendly, visible true | 1:Wave Hi 2:Bye 3:Clap 4:Thumbs Up 5:Thank You 6:Back
ZEDQA dw PASS up: the inner wheel ends with Back
ZEDQA dw PASS up: the breadcrumb names the inner wheel
ZEDQA dw PASS up: B from the inner wheel is back on the top level
ZEDQA dw PASS up: B on the top level closes the wheel
ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Light / No light on you. [off]
ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS down: the slice 'Zoom' is there
ZEDQA dw inner down: 3 slices, crumb Here and now + Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
ZEDQA dw PASS down: the inner wheel ends with Back
ZEDQA dw PASS down: the breadcrumb names the inner wheel
ZEDQA dw PASS down: B from the inner wheel is back on the top level
ZEDQA dw PASS down: B on the top level closes the wheel
ZEDQA dw foot select: 13 slices, crumb ZeD, visible true | 1:Base theme / Dark [>] 2:Accent color / PZ Teal [>] 3:Text size / Small [>] 4:See-through / 90% [>] 5:Controller highlight / Pointing hand [>] 6:UI scale [>] 7:Moodles / Right edge [>] 8:Action bar / Verbose [>] 9:Messages / No messages. [off] 10:Bug report / Copy every error for a bug report 11:Reset windows / Both windows back to where they start 12:ZeD setup / Options, on ZeD's page 13:Safe mode / The game's own interface
ZEDQA dw PASS select: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS select: the slice 'Base theme' is there
ZEDQA dw inner select: 4 slices, crumb ZeD + Base theme, visible true | 1:Dark / In use 2:Light 3:High contrast 4:Back
ZEDQA dw PASS select: the inner wheel ends with Back
ZEDQA dw PASS select: the breadcrumb names the inner wheel
ZEDQA dw PASS select: B from the inner wheel is back on the top level
ZEDQA dw PASS select: B on the top level closes the wheel
ZEDQA dw look back to dark / teal / small
ZEDQA dw PASS Character > Tabs has Health
ZEDQA dw PASS Character > Tabs > Health opened the Character window on Health
ZEDQA dw World > Map > Mini-map is off: The mini-map is off in this game.
ZEDQA dw no mini-map in this game (sandbox): the slice is off, as it should be
ZEDQA dw PASS Social > Shout is live
ZEDQA dw PASS Here and now > Zoom > in changed the zoom (1.00 -> 0.75)
ZEDQA dw PASS ZeD > Text size marks the size in use
ZEDQA dw PASS ZeD > Text size > the size in use keeps it (small)
ZEDQA dw PASS the game pauses for the paused checks
ZEDQA dw PASS paused: left stays closed
ZEDQA dw PASS paused: right stays closed
ZEDQA dw PASS paused: up stays closed
ZEDQA dw PASS paused: down opens
ZEDQA dw PASS paused: select opens
ZEDQA dw PASS the game runs again after the paused checks
ZEDQA dw PASS with a window holding the pad, D-pad Left stays in the window (no wheel)
ZEDQA dw PASS L3 steps the sort (name, cat, cond)
ZEDQA dw PASS R3 flips the bag between List and Grid (false -> true)
ZEDQA dw PASS R3 again flips it back
ZEDQA dw PASS the footer names L3 and R3 while the pad is on the list
ZEDQA dw no deep-run car within 8 tiles: the car scene is skipped
ZEDQA dw 24 animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (true)
ZEDQA dw beside a tame animal (2.0 tiles away before)
ZEDQA dw the game's usable animal: nil
ZEDQA dw animal right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal [>] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS beside a tame animal: World > Animal is live
ZEDQA dw animal wheel: 4 slices, crumb World + Animal, visible false | 1:Pick up Angus Cow 2:Pet 3:Animal Info 4:Back
ZEDQA dw PASS the animal wheel ends with Back
ZEDQA dw PASS tap: the wheel opens and stays up (held is false)
ZEDQA dw PASS tap: letting go of the D-pad does nothing
ZEDQA dw PASS below engage nothing lights
ZEDQA dw PASS slice 1 of 8 lights at its angle (1)
ZEDQA dw PASS slice 2 of 8 lights at its angle (2)
ZEDQA dw PASS slice 3 of 8 lights at its angle (3)
ZEDQA dw PASS slice 4 of 8 lights at its angle (4)
ZEDQA dw PASS slice 5 of 8 lights at its angle (5)
ZEDQA dw PASS slice 6 of 8 lights at its angle (6)
ZEDQA dw PASS slice 7 of 8 lights at its angle (7)
ZEDQA dw PASS slice 8 of 8 lights at its angle (8)
ZEDQA dw PASS past the boundary by 5 degrees: still slice 1   (x4)
ZEDQA dw PASS past it by 9: slice 2
ZEDQA dw PASS and back by 5: still slice 2, no flicker
ZEDQA dw PASS twenty slices: 5 degrees past a boundary moves (a quarter of 18 is 4.5)
ZEDQA dw PASS twenty slices: 4 degrees past holds
ZEDQA dw PASS a fast flick takes Crouch and the wheel closes
ZEDQA dw PASS easing down at 0.8: not yet
ZEDQA dw PASS easing down at 0.6: not yet
ZEDQA dw PASS easing down at 0.45: not yet
ZEDQA dw PASS easing down at 0.3: not yet
ZEDQA dw PASS easing down at 0.25: not yet
ZEDQA dw PASS a slow ease takes the same slice, not the one the last frame read
ZEDQA dw PASS the same direction closes it, nothing taken
ZEDQA dw PASS B closes it, nothing taken
ZEDQA dw PASS another direction swaps, nothing taken
ZEDQA dw PASS Select swaps to the ZeD wheel
ZEDQA dw PASS and a direction swaps back off it
ZEDQA dw PASS a second tap straight after opening is ignored
ZEDQA dw PASS a tap after the debounce closes it
ZEDQA dw PASS no engage for 3 seconds: it closes itself
ZEDQA dw PASS a slice lit: the timer waits
ZEDQA dw PASS A, X and Y do nothing with a wheel up
ZEDQA dw PASS a trigger closes the wheel, nothing taken
ZEDQA dw PASS a trigger already down when it opened is no press
ZEDQA dw PASS let go and pressed again, it is
ZEDQA dw PASS a bumper down: nothing yet
ZEDQA dw PASS LB tapped: the wheel closes, the Character window has the pad
ZEDQA dw PASS RB tapped: the wheel closes, the World window has the pad
ZEDQA dw PASS both bumpers (the zoom): the wheel stays, no windows
ZEDQA dw PASS a flick onto Zoom opens its ring in place
ZEDQA dw PASS the new ring waits for the stick to come back
ZEDQA dw PASS not centered yet: nothing lights
ZEDQA dw PASS a flick onto Back is back on the top level
ZEDQA dw PASS B backs out one level
ZEDQA dw PASS in again
ZEDQA dw PASS the same direction closes all of it
ZEDQA dw PASS the Select wheel opens by a tap too
ZEDQA dw PASS a flick on its Theme opens the ring
ZEDQA dw PASS Select again closes all of it
ZEDQA dw PASS an off slice lights
ZEDQA dw PASS letting go on it at the top level closes the wheel, as letting go always did
ZEDQA dw PASS Stick click: letting go keeps the slice lit
ZEDQA dw PASS R3 takes the lit slice, stick at rest
ZEDQA dw PASS R3 with nothing lit does nothing
ZEDQA dw PASS Hold: up while the direction is held
ZEDQA dw PASS letting go of the D-pad takes the lit slice
ZEDQA dw PASS letting the stick go first takes it too
ZEDQA dw PASS Hold with Stick click: letting the stick go does not take
ZEDQA dw PASS Hold: X closes, as it did
ZEDQA dw PASS Toggle mode forces Tap and overrides the commit
ZEDQA dw PASS D-pad Up lights the top slice
ZEDQA dw PASS D-pad Right walks the ring to slice 2
ZEDQA dw PASS no timer in Toggle mode, and the highlight stays
ZEDQA dw PASS A takes it
ZEDQA dw PASS the stick moves the highlight and letting go takes nothing
ZEDQA dw PASS B closes it
ZEDQA dw PASS dead zone 0.50: 0.45 lights nothing
ZEDQA dw PASS the dead zone is read live: at 0.40 it lights
ZEDQA dw PASS tune.ENGAGE_RADIUS wins over the setting
ZEDQA dw prompts tap flick false: RS Point | RS Let go: take | B Close
ZEDQA dw PASS prompts for tap, flick
ZEDQA dw prompts tap click false: RS Point | R3 Take | B Close
ZEDQA dw PASS prompts for tap, click
ZEDQA dw prompts hold flick false: ↓ Hold | RS Point | ↓ Let go: take | B Close
ZEDQA dw PASS prompts for hold, flick
ZEDQA dw prompts hold click false: ↓ Hold | RS Point | ↓ Let go: take | R3 Take | B Close
ZEDQA dw PASS prompts for hold, click
ZEDQA dw prompts tap flick true: RS Point | D-PAD Move | A Take | B Close
ZEDQA dw PASS prompts for tap, flick, toggle
ZEDQA dw PASS cold open: the state is up
ZEDQA dw PASS cold open: the wheel is still in the UI queue
ZEDQA dw PASS cold open: a frame on the opening tick leaves it open
ZEDQA dw PASS cold open: a few frames on it is on the screen, still working
ZEDQA dw PASS a filler a frame after the open fills the ring, Back after it
ZEDQA dw PASS the UI hidden: the wheel's state ends
ZEDQA dw PASS and the wheel is left visible for its next show, no dead state on it
ZEDQA dw PASS and it is off the screen
ZEDQA dw PASS a spring-back frame on the far side: the highlight stays
ZEDQA dw PASS and the slice taken is the lit one, never the opposite one
ZEDQA dw PASS the far side: the first frame waits
ZEDQA dw PASS a stick that stays there moves it
ZEDQA dw PASS resting at 0.25 at the open: a push still picks
ZEDQA dw PASS settling back at 0.25: not a let go, the slice stays lit
ZEDQA dw PASS left there for 3 seconds: it closes, nothing taken
ZEDQA dw PASS a new ring: passing through the band is not centered
ZEDQA dw PASS sitting in it is
ZEDQA dw PASS Stick click: the timer leaves a lit slice
ZEDQA dw PASS Toggle: the opening press lights nothing
ZEDQA dw PASS the next press does
ZEDQA dw PASS paused: Here and now opens
ZEDQA dw PASS paused: a bumper closes the wheel and no window takes the pad
ZEDQA dw gesture settings put back
ZEDQA dw 0 failed
ZEDQA dw DONE
```

### 3. zedqa_wheel_sizes.lua (`ZEDQA ws`) - PASS, 16 s

- go 21492 at 21:29:49
- screenshots: zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=924,13039 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ws no pickup within 20 tiles; spawned one beside the character: true
[ZeD.QA] run #3 ok=true
ZEDQA ws a_gun3 n=3 r=49 w=600
ZEDQA ws b_dright3 n=8 r=74 w=650
ZEDQA ws c_emotes5 n=5 r=49 w=600
ZEDQA ws d_signal9 n=9 r=83 w=668
ZEDQA ws e_back10 n=13 r=119 w=740
ZEDQA ws g_car11 n=11 r=101 w=704
ZEDQA ws h_car11pt n=11 r=101 w=704
ZEDQA ws done
```

### 4. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 59 s

- go 21493 at 21:30:09
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=918,13038 grid=19 inCar=false vehicles=54 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wi no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wi start car=BaseVehicle{ Name:null, ID:114 }
[ZeD.QA] run #4 ok=true
ZEDQA wi scene: screen 3840x2160, scale option 7, icon box 28 at rest, 42 pointed
ZEDQA wi PASS all 154 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 28 draws the 24, box 42 draws the 32
ZEDQA wi PASS vanilla's words: 29 of 30 give their icon over vanilla's picture
ZEDQA wi NOTE no words in this language for ContextMenu_Vehicle_AttachVehicle (vanilla shows the key itself; nothing to match)
ZEDQA wi PASS vanilla's pictures by name, in order: 95 of 95
ZEDQA wi PASS items, traits and the controller's glyphs keep their pictures
ZEDQA wi PASS headlights on / a light source on share a picture and come out id:headlight_on / id:bulb_on
ZEDQA wi PASS headlights off / a light source off share a picture and come out id:headlight_off / id:bulb_off
ZEDQA wi PASS get in / change seats share a picture and come out id:car_enter / id:seat
ZEDQA wi PASS get out / a door share a picture and come out id:car_exit / id:car_door
ZEDQA wi PASS lock / unlock share a picture and come out id:padlock / id:padlock_open
ZEDQA wi PASS hitch / unhitch share a picture and come out id:link / id:unlink
ZEDQA wi PASS zoom in / plus share a picture and come out id:zoom_in / id:plus
ZEDQA wi PASS zoom out / minus share a picture and come out id:zoom_out / id:minus
ZEDQA wi PASS the tab icons, and every tab of both windows has one
ZEDQA wi PASS left: the wheel builds
ZEDQA wi PASS right: the wheel builds
ZEDQA wi PASS up: the wheel builds
ZEDQA wi PASS down: the wheel builds
ZEDQA wi PASS select: the wheel builds
ZEDQA wi PASS 142 slices on ZeD's five wheels, 125 with a wheel icon, the rest items, glyphs or colours
ZEDQA wi PASS the ZeD wheel's pickers give their choices the setting's icon
ZEDQA wi PASS the map's slices on ZeD's wheels: 80 with their icon
ZEDQA wi NOTE not on the wheels now (the state decides): the wounds (no wound now); character > Watch / UI_ZeD_Wheel_OpenWatch; character > Watch / UI_ZeD_Wheel_WatchLight; character > Watch / UI_ZeD_Wheel_WatchAlarm; character > Radio / UI_ZeD_Wheel_NextStation; world > Search / UI_disable_search_mode; world > Vehicle / IGUI_VehiclePartCatdashboard
ZEDQA wi PASS Crouch and Auto-walk show what the slice does now: sneak, autowalk
ZEDQA wi dpad_left: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Light/No light on you.=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select: 13 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Bug report/Copy every error for a bug report=bullhorn 11:Reset windows/Both windows back to where they start=rotate 12:ZeD setup/Options, on ZeD's page=gears 13:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke/Nothing to smoke, or nothing to light it.=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_friendly: 6 slices | 1:Wave Hi=wave 2:Bye=wave_bye 3:Clap=clap 4:Thumbs Up=thumbs_up 5:Thank You=bow
ZEDQA wi PASS emotes_friendly: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_hostile: 5 slices | 1:Insult=insult 2:Stop=hand 3:Surrender=surrender 4:Thumbs Down=thumbs_down
ZEDQA wi PASS emotes_hostile: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_group: 7 slices | 1:Follow Me=follow_me 2:Come Here=come_here 3:Yes=yes 4:No=no 5:Shrug=shrug 6:Undecided=undecided
ZEDQA wi PASS emotes_group: 6 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_signal: 9 slices | 1:Cease Fire=target_off 2:Ok=yes 3:Move Out=move_out 4:Freeze=freeze 5:Follow Behind=follow_behind 6:Fire=target 7:Come=come_here 8:Salute=salute
ZEDQA wi PASS emotes_signal: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 10 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_outside: 0 slices |
ZEDQA wi NOTE car_outside: the wheel is empty here
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 13 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 122 slices, 120 wheel icons, 2 kept pictures
ZEDQA wi now at 1x (text size small): icon box 16 at rest, 24 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_1x: 13 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Bug report/Copy every error for a bug report=bullhorn 11:Reset windows/Both windows back to where they start=rotate 12:ZeD setup/Options, on ZeD's page=gears 13:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi scale back to option 7: icon box 28
ZEDQA wi 0 failed, 3 notes
ZEDQA wi DONE
```

### 5. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 28 s

- go 21494 at 21:31:11
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=912,13037 grid=19 inCar=false vehicles=54 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wh no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wh start car=BaseVehicle{ Name:null, ID:115 } pistol=nil torch=nil
[ZeD.QA] run #5 ok=true
ZEDQA wh outside zed=true java=UIElement n=0 x=1716 y=876 w=408 vis=false point=-1 title=nil |
ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.[off] 3:Turn Headlights on 4:Turn AC/Heater on 5:Horn 6:Device Options 7:Open Window 8:Lock all doors 9:Vehicle Mechanics 10:Not tired enough to sleep.[off] 11:Exit Vehicle
ZEDQA wh pick test slice3 from mouse -> 3
ZEDQA wh emotes zed=true java=UIElement n=5 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout
ZEDQA wh press towards 4 (Signal)
ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
ZEDQA wh gun zed=true java=UIElement n=0 x=1586 y=746 w=668 vis=false point=-1 title=nil |
ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Lighter/Equip Primary 2:Lighter/Equip Secondary
ZEDQA wh back zed=true java=UIElement n=13 x=1550 y=710 w=740 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/PZ Teal 3:Text size/Small 4:See-through/90% 5:Controller highlight/Pointing hand 6:UI scale 7:Moodles/Right edge 8:Action bar/Verbose 9:Messages/No messages.[off] 10:Bug report/Copy every error for a bug report 11:Reset windows/Both windows back to where they start 12:ZeD setup/Options, on ZeD's page 13:Safe mode/The game's own interface
ZEDQA wh dright zed=true java=UIElement n=8 x=1595 y=755 w=650 vis=false point=-1 title=nil | 1:Tabs/World window 2:Map 3:Vehicle/No vehicle in reach.[off] 4:Animal/No tame animal in reach.[off] 5:Craft and build 6:Search 7:Lights and power/No lights or power in reach.[off] 8:Designated Zones/Animals
ZEDQA wh zone route: world=true vanillaZone=false
ZEDQA wh zone tab showing=true
ZEDQA wh search route: forage showing=true vanillaSearch=false
ZEDQA wh player info route: char=true vanillaInfo=false
ZEDQA wh DONE
```

### 6. zedqa_pad_glyphs.lua (`ZEDQA pg`) - PASS, 34 s

- go 21495 at 21:31:43
- screenshots: zqa_pg_footer_ps.png, zqa_pg_wheel_ps.png, zqa_pg_footer_xbox.png, zqa_pg_wheel_xbox.png, zqa_pg_footer_deck.png, zqa_pg_wheel_deck.png, zqa_pg_footer_nintendo.png, zqa_pg_wheel_nintendo.png, zqa_pg_footer_kbm.png, zqa_pg_wheel_kbm.png, zqa_pg_footer_ps_light.png, zqa_pg_wheel_ps_light.png, zqa_pg_footer_ps_hicon.png, zqa_pg_wheel_ps_hicon.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=906,13036 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pg start
[ZeD.QA] run #6 ok=true
ZEDQA pg scene: glyph setting xbox, the game's style XBOX, input gamepad
ZEDQA pg PASS ps: the setting reads ps
ZEDQA pg PASS ps: the set in use is ps
ZEDQA pg ps: footer pictures drawn in 10 ticks: 60
ZEDQA pg PASS ps: the footer draws its buttons as pictures
ZEDQA pg ps: wheel pictures drawn in 5 ticks: 18
ZEDQA pg PASS ps: the wheel's prompts are pictures
ZEDQA pg PASS xbox: the setting reads xbox
ZEDQA pg PASS xbox: the set in use is xbox
ZEDQA pg xbox: footer pictures drawn in 10 ticks: 60
ZEDQA pg PASS xbox: the footer draws its buttons as pictures
ZEDQA pg xbox: wheel pictures drawn in 5 ticks: 12
ZEDQA pg PASS xbox: the wheel's prompts are pictures
ZEDQA pg PASS deck: the setting reads deck
ZEDQA pg PASS deck: the set in use is deck
ZEDQA pg deck: footer pictures drawn in 10 ticks: 60
ZEDQA pg PASS deck: the footer draws its buttons as pictures
ZEDQA pg deck: wheel pictures drawn in 5 ticks: 12
ZEDQA pg PASS deck: the wheel's prompts are pictures
ZEDQA pg PASS nintendo: the setting reads nintendo
ZEDQA pg PASS nintendo: the set in use is nin
ZEDQA pg nintendo: footer pictures drawn in 10 ticks: 60
ZEDQA pg PASS nintendo: the footer draws its buttons as pictures
ZEDQA pg nintendo: wheel pictures drawn in 5 ticks: 18
ZEDQA pg PASS nintendo: the wheel's prompts are pictures
ZEDQA pg PASS kbm: the setting reads kbm
ZEDQA pg PASS kbm: the set in use is nil
ZEDQA pg kbm: footer pictures drawn in 10 ticks: 0
ZEDQA pg PASS kbm: the footer draws boxed names, no pictures
ZEDQA pg kbm: wheel pictures drawn in 5 ticks: 0
ZEDQA pg no deep-run car within 8 tiles: the dash scene is skipped
ZEDQA pg put back: glyph setting xbox, input lock nil
ZEDQA pg all checks passed
ZEDQA pg DONE
```

### 7. zedqa_quick_chords.lua (`ZEDQA qc`) - PASS, 25 s

- go 21496 at 21:32:20
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] state #7 speed=1 paused=false player=906,13036 grid=19 inCar=false vehicles=56 missing=get
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #7 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
ZEDQA qc LB+A = character:3 (Character > Eat): Eat
ZEDQA qc PASS LB+A: the default names a slice
ZEDQA qc LB+B = character:4 (Character > Drink): Drink
ZEDQA qc PASS LB+B: the default names a slice
ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
ZEDQA qc PASS LB+X: the default names a slice
ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
ZEDQA qc PASS LB+Y: the default names a slice
ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
ZEDQA qc PASS LB+L3: the default names a slice
ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
ZEDQA qc PASS LB+R3: the default names a slice
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid
ZEDQA qc PASS RB+A: the default names a slice
ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
ZEDQA qc PASS RB+B: the default names a slice
ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
ZEDQA qc PASS RB+X: the default names a slice
ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
ZEDQA qc PASS RB+Y: the default names a slice
ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
ZEDQA qc PASS RB+L3: the default names a slice
ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
ZEDQA qc PASS RB+R3: the default names a slice
ZEDQA qc LB + X queued: ISEquipWeaponAction
ZEDQA qc PASS LB + X: the game's prompts never saw X
ZEDQA qc PASS a light for LB + X
ZEDQA qc PASS LB + X: the light is in a hand
ZEDQA qc PASS LB + X: the light is on
ZEDQA qc PASS LB + X again: the light is off
ZEDQA qc LB + X from a bag queued: ISInventoryTransferAction, ISEquipWeaponAction
ZEDQA qc PASS LB + X from a bag: the light is out of the bag
ZEDQA qc PASS LB + X from a bag: the light is in a hand
ZEDQA qc PASS LB + X from a bag: the light is on
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
ZEDQA qc PASS LB + Y (smoke): the game queues its action
ZEDQA qc said: No QA Gone on you.
ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
ZEDQA qc PASS the Here and now wheel is open
ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
ZEDQA qc PASS the bubble says what it did
ZEDQA qc PASS opened again: Crouch shows RB + Y
ZEDQA qc PASS the stick lights Crouch
ZEDQA qc PASS a bumper held: the stick let go takes nothing and the slice stays lit
ZEDQA qc PASS the button assigns the lit slice: now:2
ZEDQA qc PASS the bumper let go after a chord: no close, no windows
ZEDQA qc PASS B closes it, nothing taken
ZEDQA qc PASS ZeD setup is open on the pause screen
ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
ZEDQA qc PASS ZeD setup has Put things back
ZEDQA qc the list for LB+A: 93 items, 85 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc all checks passed
ZEDQA qc DONE
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
