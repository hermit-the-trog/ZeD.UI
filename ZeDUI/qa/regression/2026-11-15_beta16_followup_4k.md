# ZeD-UI regression - 2026-11-15 20:19 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-15 20:19:07 |
| Finished | 2026-11-15 20:23:42 (4 min 35 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta16 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b16_followup.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 27550 to 27555 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27554, 27555)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b16.lua | b16 | PASS | 19 | zqa_b16_oven_popout.png, zqa_b16_microwave_popout.png, zqa_b16_tv_popout.png, zqa_b16_speed_paused.png, zqa_b16_speed_3x.png, zqa_b16_speed_normal.png |  |
| 3 | zedqa_twoway.lua | tw | PASS | 56 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 4 | zedqa_rtv.lua | rtv | PASS | 97 | zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_plain_card.png, zqa_rtv_3_plain_card_no_face.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27550 at 20:20:13

```text
[ZeD.QA] state #1 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta16 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_b16.lua (`ZEDQA b16`) - PASS, 19 s

- go 27551 at 20:20:19
- screenshots: zqa_b16_oven_popout.png, zqa_b16_microwave_popout.png, zqa_b16_tv_popout.png, zqa_b16_speed_paused.png, zqa_b16_speed_3x.png, zqa_b16_speed_normal.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b16 start
[ZeD.QA] run #2 ok=true
ZEDQA b16 PASS faces pop out (Devices on Immersive, safe mode off)
ZEDQA b16 PASS an oven, a microwave and a TV placed beside the character
ZEDQA b16 PASS oven: its face pops out
ZEDQA b16 PASS oven: the pop-out shows, frameless
ZEDQA b16 PASS oven: it shows this machine
ZEDQA b16 PASS oven: the same machine again puts it away
ZEDQA b16 PASS microwave: its face pops out
ZEDQA b16 PASS microwave: the pop-out shows, frameless
    LOG  : Lua          f:569> ZEDQA b16 PASS microwave: it shows this machine
    OG  : Lua          f:590> ZEDQA b16 PASS microwave: the same machine again puts it away
ZEDQA b16 PASS tv: its face pops out
ZEDQA b16 PASS tv: the pop-out shows, frameless
ZEDQA b16 PASS tv: it shows this machine
ZEDQA b16 PASS tv: the same machine again puts it away
ZEDQA b16 PASS another machine's pop-out replaces the first
ZEDQA b16 PASS paused: a speed note over the head (0)
ZEDQA b16 PASS at 3x: the speed note shows the arrows (3)
ZEDQA b16 at normal speed the note reads 3 (expect it gone from over the head)
ZEDQA b16 seat pop-out on CarNormalSmashedFront 7 tiles away: fell back to the window (the car can't be laid out)
ZEDQA b16 all checks passed
ZEDQA b16 DONE
```

### 3. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 56 s

- go 27552 at 20:20:41
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #3 ok=true
ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
ZEDQA tw PASS walkie_valutech: the width that fills the half card (want walkie_valutech@180, got walkie_valutech@180)
ZEDQA tw PASS walkie_valutech: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 101.200 | KNOXTALK RADIO | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw valutech: the face and footer need 1190 px with 380 px of fill blocks (body 585)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (101200 -> 101400)
ZEDQA tw PASS TUNE: its left half tunes down a step
ZEDQA tw PASS TUNE: a right-click turns it down
ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
ZEDQA tw PASS the display shows CH 01 (01)
ZEDQA tw PASS MEM: a second channel stored
ZEDQA tw PASS CH down walks to channel 01
ZEDQA tw PASS CH up walks to channel 02
ZEDQA tw PASS the mic starts muted
ZEDQA tw PASS the TX lamp is dark while the mic is muted
ZEDQA tw PASS PUSH TO TALK latches the mic live
ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
ZEDQA tw PASS MEM held (right-click): the naming box opens
ZEDQA tw PASS naming it: channel 02 is QA Farm
ZEDQA tw PASS the header button opens full view on the radio
ZEDQA tw PASS full view is the face alone, no window frame
ZEDQA tw PASS full view is the plate at the plate scale, room for its 1u hard shadow (402x766)
ZEDQA tw PASS the first time it sits beside the player, clear of them (x 1984, player 1920)
ZEDQA tw PASS every control is on it (6)
ZEDQA tw PASS a control in full view works (CH down)
ZEDQA tw PASS MEM held in full view opens the naming box
ZEDQA tw PASS the face's edge is not a control
ZEDQA tw PASS dragging the face moves full view (1984 -> 1584)
ZEDQA tw PASS the place is kept on the character
ZEDQA tw PASS the header button closes full view
ZEDQA tw PASS the point between the knobs is no control
ZEDQA tw PASS a click on the face away from the controls opens full view
ZEDQA tw PASS it opens where it was dragged to
ZEDQA tw PASS B closes full view
ZEDQA tw PASS Escape closes full view
ZEDQA tw PASS full view closes when the radio leaves the hands
ZEDQA tw PASS pad: the face's VOL is a stop in the tab
ZEDQA tw PASS pad: up on VOL turns it up
ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
ZEDQA tw PASS pad: A on CH up steps the channel
ZEDQA tw PASS pad: X on MEM opens the naming box
ZEDQA tw PASS pad: A on the full view button opens it
ZEDQA tw PASS pad: full view shows its controller strip
ZEDQA tw PASS pad: full view lands on a control (vol)
ZEDQA tw PASS pad: down on VOL in full view turns it down
ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
ZEDQA tw PASS pad: B closes full view
ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy@180)
ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_toy: the width that fills the half card (want walkie_toy@180, got walkie_toy@180)
ZEDQA tw PASS walkie_toy: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 98.40 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium@180)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_premium: the width that fills the half card (want walkie_premium@180, got walkie_premium@180)
ZEDQA tw PASS walkie_premium: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 204.200 | | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_tactical: the width that fills the half card (want walkie_tactical@180, got walkie_tactical@180)
ZEDQA tw PASS walkie_tactical: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 098.000 | NNR RADIO | BAT 3
ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
ZEDQA tw PASS Tactical: MUTE silences it
ZEDQA tw PASS Tactical: MUTE again gives the sound back
ZEDQA tw PASS Tactical: SCAN runs
ZEDQA tw PASS Tactical: SCAN again stops it
ZEDQA tw PASS Tactical: LAMP lights the display
ZEDQA tw PASS Tactical: the lamp goes out after 5 s
ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army@180)
ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_army: the width that fills the half card (want walkie_army@180, got walkie_army@180)
ZEDQA tw PASS walkie_army: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 094.200 | USR | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_makeshift: the width that fills the half card (want walkie_makeshift@180, got walkie_makeshift@180)
ZEDQA tw PASS walkie_makeshift: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 98.00 | NNR RADIO | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 98.00)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
ZEDQA tw PASS walkie_manpack: the width that fills the half card (want walkie_manpack@180, got walkie_manpack@180)
ZEDQA tw PASS walkie_manpack: the tab is the half card where a width fits (385 px; panel 180, card 385)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 095.000 | CLASSIFIED M1A1 | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio shows its own face (or plain card), not a two-way set's
ZEDQA tw 8 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian@392)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 089.400 | HITZ FM | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (20 sets, 20 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.1620408163265306 -> 0.2640816326530612)
ZEDQA tw PASS civilian ham: full view opens
ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
ZEDQA tw PASS ham_civilian: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_civilian: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_civilian: the narrow face's display reads
ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
ZEDQA tw PASS ham_army: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_army: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_army: the narrow face's display reads
ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
ZEDQA tw PASS ham_makeshift: the tab is the half card (385 px, want 385)
ZEDQA tw PASS ham_makeshift: the narrow face at a whole zoom that fits the half card (1 of the screen's 2)
ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_makeshift: the narrow face's display reads
ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
ZEDQA tw PASS with room again the wide set is back
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army@392)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_army: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 098.600 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift@392)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 28, want 28)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 784)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 101.400 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 192 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 4. zedqa_rtv.lua (`ZEDQA rtv`) - PASS, 97 s

- go 27553 at 20:21:41
- screenshots: zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_plain_card.png, zqa_rtv_3_plain_card_no_face.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=924,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtv start
[ZeD.QA] run #4 ok=true
ZEDQA rtv screen 3840x2160, root scale 1.75, plate zoom 2
ZEDQA rtv PASS radio_black: the Character window's Radio tab opens
ZEDQA rtv PASS radio_black: its own face, radio_black (got radio_black)
ZEDQA rtv PASS radio_black: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_black: the width that fills the half card (radio_black, got radio_black)
ZEDQA rtv PASS radio_black: centred in the card, left gap 20, right gap 20
ZEDQA rtv PASS radio_black: the face fills the card (gaps 20 / 20, at most 35)
ZEDQA rtv PASS radio_black: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS radio_black: every control on the face (11 of 11)
ZEDQA rtv PASS radio_black: POWER turns it on
ZEDQA rtv PASS radio_black: the display reads and the lamp lights while on
ZEDQA rtv radio_black: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_black: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_black: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_black: tuned away
ZEDQA rtv PASS radio_black: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_black: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_black: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_red: the Character window's Radio tab opens
ZEDQA rtv PASS radio_red: its own face, radio_red (got radio_red)
ZEDQA rtv PASS radio_red: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_red: the width that fills the half card (radio_red, got radio_red)
ZEDQA rtv PASS radio_red: centred in the card, left gap 20, right gap 20
ZEDQA rtv PASS radio_red: the face fills the card (gaps 20 / 20, at most 35)
ZEDQA rtv PASS radio_red: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS radio_red: every control on the face (14 of 14)
ZEDQA rtv PASS radio_red: POWER turns it on
ZEDQA rtv PASS radio_red: the display reads and the lamp lights while on
ZEDQA rtv radio_red: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_red: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_red: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_red: tuned away
ZEDQA rtv PASS radio_red: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_red: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_red: the slot opens the list of discs carried
ZEDQA rtv PASS radio_red: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_handbuilt: the Character window's Radio tab opens
ZEDQA rtv PASS radio_handbuilt: its own face, radio_handbuilt (got radio_handbuilt)
ZEDQA rtv PASS radio_handbuilt: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS radio_handbuilt: the width that fills the half card (radio_handbuilt, got radio_handbuilt)
ZEDQA rtv PASS radio_handbuilt: centred in the card, left gap 20, right gap 20
ZEDQA rtv PASS radio_handbuilt: the face fills the card (gaps 20 / 20, at most 35)
ZEDQA rtv PASS radio_handbuilt: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS radio_handbuilt: every control on the face (10 of 10)
ZEDQA rtv PASS radio_handbuilt: POWER turns it on
ZEDQA rtv PASS radio_handbuilt: the display reads and the lamp lights while on
ZEDQA rtv radio_handbuilt: display FM 98.0 MHZ | NNR RADIO | batt 3
ZEDQA rtv PASS radio_handbuilt: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_handbuilt: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_handbuilt: tuned away
ZEDQA rtv PASS radio_handbuilt: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_handbuilt: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_handbuilt: the headphone jack queues vanilla's action
ZEDQA rtv PASS cd_player: the Character window's Radio tab opens
ZEDQA rtv PASS cd_player: its own face, cd_player (got cd_player)
ZEDQA rtv PASS cd_player: the half card where a width fits, else the full (385 px, want 385)
ZEDQA rtv PASS cd_player: the width that fills the half card (cd_player, got cd_player)
ZEDQA rtv PASS cd_player: centred in the card, left gap 20, right gap 20
ZEDQA rtv PASS cd_player: the face fills the card (gaps 20 / 20, at most 35)
ZEDQA rtv PASS cd_player: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS cd_player: every control on the face (9 of 9)
ZEDQA rtv PASS cd_player: POWER turns it on
ZEDQA rtv PASS cd_player: the display reads and the lamp lights while on
ZEDQA rtv cd_player: display -:-- | NO DISC | batt 3
ZEDQA rtv PASS cd_player: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS cd_player: the battery key queues vanilla's battery action
ZEDQA rtv PASS cd_player: the slot opens the list of discs carried
ZEDQA rtv PASS cd_player: the headphone jack queues vanilla's action
ZEDQA rtv PASS controller: POWER is the first stop on the face (got radio:tw:power)
ZEDQA rtv PASS controller: every control is a stop (9)
ZEDQA rtv PASS cd_player: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS cd_player: the pad's A on battery opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on battery (radio:tw:battery)
ZEDQA rtv PASS cd_player: the pad's A on phones opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS cd_player: the pad's A on slot opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS Devices on Simple: the cd_player draws the plain card (PlainFace), with its power switch
ZEDQA rtv PASS no face of its own: the CD player stands in for a modded radio
ZEDQA rtv PASS no face of its own (Devices on Immersive): the plain card with the black radio's controls (radio_black)
ZEDQA rtv PASS no face of its own: the plain card's power switch works
ZEDQA rtv PASS its face back, Devices on Immersive: the face is drawn again
ZEDQA rtv indoors at 892,13005 (5 free room squares round it)
ZEDQA rtv grid: world power true, this square haveElectricity false, hasGridPower true, in a room true
ZEDQA rtv PASS the staging square has grid power
ZEDQA rtv placed 4 sets (round the character, on their squares)
ZEDQA rtv PASS the World window lists the placed sets (4)
ZEDQA rtv PASS the World window's Radio tab opens on the placed sets
ZEDQA rtv PASS radio_red (placed, by its tile): its own face, radio_red (got radio_red@392)
ZEDQA rtv PASS radio_red (placed, by its tile): the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS radio_red (placed, by its tile): centred in the card, left gap 15, right gap 16
ZEDQA rtv PASS radio_red (placed, by its tile): the face fills the card (gaps 15 / 16, at most 35)
ZEDQA rtv PASS radio_red (placed, by its tile): the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS radio_red (placed, by its tile): every control on the face (14 of 14)
ZEDQA rtv PASS tv_black (placed, by its tile): its own face, tv_black (got tv_black@392)
ZEDQA rtv PASS tv_black (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_black (placed, by its tile): the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS tv_black (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_black: the set has grid power (true)
ZEDQA rtv PASS tv_black: NO POWER dark on the grid
ZEDQA rtv PASS tv_black: off to start with
ZEDQA rtv PASS tv_black: power turns it on
ZEDQA rtv PASS tv_black: the power lamp lights
ZEDQA rtv PASS tv_black: the channel display reads (05)
ZEDQA rtv PASS tv_black: on the first stop (1)
ZEDQA rtv PASS tv_black: CH up: the second stop (2)
ZEDQA rtv PASS tv_black: CH down: back to the first (1)
ZEDQA rtv PASS tv_black: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_black: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_black: VOL up raises the volume
ZEDQA rtv PASS tv_black: VOL down lowers it again
ZEDQA rtv PASS tv_black: just changed channel: snow (snow)
ZEDQA rtv tv_black: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 12: the display reads it
ZEDQA rtv tv_black: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 13: the display reads it
ZEDQA rtv PASS tv_black: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_black: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_black: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_black: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_black: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_black: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_black: power again turns it off
ZEDQA rtv PASS tv_black: with the grid off the set reports no power
ZEDQA rtv PASS tv_black: NO POWER lit without the grid
ZEDQA rtv PASS tv_black: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_black: the grid back on: the set has power again
ZEDQA rtv PASS tv_black: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS tv_black: the pad's A on slot opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS tv_black: the pad's A on phones opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_widescreen: the set has grid power (true)
ZEDQA rtv PASS tv_widescreen: NO POWER dark on the grid
ZEDQA rtv PASS tv_widescreen: off to start with
ZEDQA rtv PASS tv_widescreen: power turns it on
ZEDQA rtv PASS tv_widescreen: the power lamp lights
ZEDQA rtv PASS tv_widescreen: the channel display reads (09)
ZEDQA rtv PASS tv_widescreen: on the first stop (1)
ZEDQA rtv PASS tv_widescreen: CH up: the second stop (2)
ZEDQA rtv PASS tv_widescreen: CH down: back to the first (1)
ZEDQA rtv PASS tv_widescreen: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_widescreen: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_widescreen: VOL up raises the volume
ZEDQA rtv PASS tv_widescreen: VOL down lowers it again
ZEDQA rtv PASS tv_widescreen: just changed channel: snow (snow)
ZEDQA rtv tv_widescreen: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 12: the display reads it
ZEDQA rtv tv_widescreen: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 13: the display reads it
ZEDQA rtv PASS tv_widescreen: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_widescreen: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_widescreen: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_widescreen: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_widescreen: power again turns it off
ZEDQA rtv PASS tv_widescreen: with the grid off the set reports no power
ZEDQA rtv PASS tv_widescreen: NO POWER lit without the grid
ZEDQA rtv PASS tv_widescreen: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_widescreen: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique (placed, by its tile): its own face, tv_antique (got tv_antique@392)
ZEDQA rtv PASS tv_antique (placed, by its tile): the full card (840 px)
ZEDQA rtv PASS tv_antique (placed, by its tile): the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS tv_antique (placed, by its tile): every control on the face (4 of 4)
ZEDQA rtv PASS tv_antique: the volume knob is one control (volpwr), the channel dial another
ZEDQA rtv PASS tv_antique: the set has grid power (true)
ZEDQA rtv PASS tv_antique: NO POWER dark on the grid
ZEDQA rtv PASS tv_antique: off to start with
ZEDQA rtv PASS tv_antique: power turns it on
ZEDQA rtv PASS tv_antique: the power lamp lights
ZEDQA rtv PASS tv_antique: the channel display reads (03)
ZEDQA rtv PASS tv_antique: eleven clicks up the dial: the twelfth stop (12)
ZEDQA rtv PASS tv_antique: the dial's pointer is on the twelfth mark (11)
ZEDQA rtv PASS tv_antique: the dial stops at its upper end (12)
ZEDQA rtv PASS tv_antique: eleven clicks down: the first stop (1)
ZEDQA rtv PASS tv_antique: the dial stops at its lower end (1)
ZEDQA rtv PASS tv_antique: a click on the dial's right half: up a stop (2)
ZEDQA rtv PASS tv_antique: its left half: down a stop (1)
ZEDQA rtv PASS tv_antique: the knob turned: the volume rises
ZEDQA rtv PASS tv_antique: the knob turned: still on
ZEDQA rtv PASS tv_antique: the knob pulled: off
ZEDQA rtv PASS tv_antique: the knob pushed: on again
ZEDQA rtv PASS tv_antique: just changed channel: snow (snow)
ZEDQA rtv tv_antique: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 12: the display reads it
ZEDQA rtv tv_antique: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 13: the display reads it
ZEDQA rtv PASS tv_antique: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_antique: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_antique: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_antique: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_antique: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_antique: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_antique: power again turns it off
ZEDQA rtv PASS tv_antique: with the grid off the set reports no power
ZEDQA rtv PASS tv_antique: NO POWER lit without the grid
ZEDQA rtv PASS tv_antique: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_antique: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique: the pad lands on power when it enters the tab (radio:tw:volpwr)
ZEDQA rtv PASS tv_antique: pad: X on the knob powers it
ZEDQA rtv PASS tv_antique: pad: A grabs the knob and up turns the volume, the set stays on
ZEDQA rtv PASS tv_antique: pad: A grabs the dial and up turns it a stop up (4)
ZEDQA rtv PASS tv_antique: pad: X on the knob again: off
ZEDQA rtv PASS every off-air screen's texture loads (0 missing)
ZEDQA rtv PASS the game's own logo loads: triple_n
ZEDQA rtv PASS the game's own logo loads: turbo
ZEDQA rtv PASS controller: the set's power is the first stop (radio:tw:volpwr)
ZEDQA rtv house tiles: bare radio appliances_radio_01_20; CustomItem radio appliances_radio_01_3 (radio_black); CustomItem TV appliances_television_01_3 (tv_widescreen)
ZEDQA rtv PASS house radio tile appliances_radio_01_20: no face of its own without a dropped item
ZEDQA rtv PASS house radio dropped as an item (RadioItemID): the item's face (radio_black)
ZEDQA rtv PASS house radio tile appliances_radio_01_3 (CustomItem): radio_black (radio_black)
ZEDQA rtv PASS house TV tile appliances_television_01_3 (CustomItem): tv_widescreen (tv_widescreen)
ZEDQA rtv PASS the World window lists the house sets (3)
ZEDQA rtv PASS house_bare in the Radio tab: its own face, radio_black (got radio_black@392)
ZEDQA rtv PASS house_bare in the Radio tab: the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS house_bare in the Radio tab: centred in the card, left gap 15, right gap 16
ZEDQA rtv PASS house_bare in the Radio tab: the face fills the card (gaps 15 / 16, at most 35)
ZEDQA rtv PASS house_bare in the Radio tab: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS house_bare in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_bare: on the grid (true)
ZEDQA rtv PASS house_ci_radio in the Radio tab: its own face, radio_black (got radio_black@392)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the World window's full card (the half card only held in) (840 px, want 840)
ZEDQA rtv PASS house_ci_radio in the Radio tab: centred in the card, left gap 15, right gap 16
ZEDQA rtv PASS house_ci_radio in the Radio tab: the face fills the card (gaps 15 / 16, at most 35)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS house_ci_radio in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_ci_radio: on the grid (true)
ZEDQA rtv PASS house_ci_tv in the Radio tab: its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS house_ci_tv in the Radio tab: the full card (840 px)
ZEDQA rtv PASS house_ci_tv in the Radio tab: the pop-out button in the header (beta 16: every face pops out)
ZEDQA rtv PASS house_ci_tv in the Radio tab: every control on the face (10 of 10)
ZEDQA rtv PASS house_ci_tv: on the grid (true)
ZEDQA rtv cleanup: sets, house sets and 7 items taken away
ZEDQA rtv back at 924,13037
ZEDQA rtv 219 passed, 0 failed
ZEDQA rtv all checks passed
ZEDQA rtv DONE
ERROR: General f:4938 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
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
