# ZeD-UI regression - 2026-11-02 21:53 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 21:53:00 |
| Finished | 2026-11-02 21:56:36 (3 min 36 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/gallery_beta.txt (11 scripts) |
| Result | **10/11 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 19143 to 19155 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19154, 19155)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 4 | zedqa_twoway.lua | tw | PASS | 46 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 5 | gallery_t14_look.lua | g14l2 | PASS | 1 |  |  |
| 6 | zedqa_gallery_t4.lua | g4 | PASS | 10 | zqa_g4_belt_toast.png, zqa_g4_window_note.png, zqa_g4_window_radio.png |  |
| 7 | gallery_only_laundry.lua | gol | PASS | 1 |  |  |
| 8 | gallery_t14_indoor.lua | g14i | **FAIL** | 15 |  | 3 Java exception(s) in the log |
| 9 | gallery_t14_look.lua | g14l3 | PASS | 1 |  |  |
| 10 | gallery_beta_new.lua | gbn | PASS | 21 |  | 2 expected exception(s) ignored (expect=) |
| 11 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 19143 at 21:53:58

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 19144 at 21:54:03

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 19145 at 21:54:07

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 15.99 -> 11.00
[ZeD.QA] run #3 ok=true
ZEDQA day DONE
```

### 4. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 46 s

- go 19146 at 21:54:12
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #4 ok=true
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
ZEDQA tw walkie_valutech: display 094.200 | USR | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 585 px tall, the face's body needs 799 (window 735)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (94200 -> 94400)
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
ZEDQA tw PASS full view is the plate at the plate scale, room for its 1u hard shadow (402x722)
ZEDQA tw PASS the first time it sits centre right of the play area (centre x 2880)
ZEDQA tw PASS every control is on it (6)
ZEDQA tw PASS a control in full view works (CH down)
ZEDQA tw PASS MEM held in full view opens the naming box
ZEDQA tw PASS the face's edge is not a control
ZEDQA tw PASS dragging the face moves full view (2679 -> 2279)
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
ZEDQA tw walkie_toy: display 101.20 MHZ | nil | nil nil
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
ZEDQA tw walkie_premium: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
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
ZEDQA tw walkie_tactical: display 444.200 | | BAT 3
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
ZEDQA tw walkie_army: display 087.400 | | BAT 3
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
ZEDQA tw walkie_makeshift: display CH-- 112.60 | | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 112.60)
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
ZEDQA tw walkie_manpack: display 089.400 | HITZ FM | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio with faces off shows the chassis (the simple card)
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
ZEDQA tw ham_civilian: display 344.600 | | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (20 sets, 20 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.6828571428571428 -> 0.7848979591836734)
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
ZEDQA tw ham_army: display 860.200 | | range RANGE 20 KM
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
ZEDQA tw ham_makeshift: display CH-- 098.200 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 192 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 5. gallery_t14_look.lua (`ZEDQA g14l2`) - PASS, 1 s

- go 19147 at 21:55:02

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l2 desk menu bar: Debug left out true
ZEDQA g14l2 position readout and cheat lines off true
ZEDQA g14l2 left-edge column hidden true
ZEDQA g14l2 look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #5 ok=true
ZEDQA g14l2 DONE
```

### 6. zedqa_gallery_t4.lua (`ZEDQA g4`) - PASS, 10 s

- go 19148 at 21:55:06
- screenshots: zqa_g4_belt_toast.png, zqa_g4_window_note.png, zqa_g4_window_radio.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g4 start
[ZeD.QA] run #6 ok=true
ZEDQA g4 shot belt_toast
ZEDQA g4 shot window_note
ZEDQA g4 shot window_radio
ZEDQA g4 put back: dark orange
ZEDQA g4 DONE
```

### 7. gallery_only_laundry.lua (`ZEDQA gol`) - PASS, 1 s

- go 19149 at 21:55:19

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gol GAL14_ONLY laundry
[ZeD.QA] run #7 ok=true
ZEDQA gol DONE
```

### 8. gallery_t14_indoor.lua (`ZEDQA g14i`) - FAIL, 15 s

- go 19150 at 21:55:23
- 3 Java exception(s) in the log

```text
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14i start
[ZeD.QA] run #8 ok=true
ZEDQA g14i indoors at 892,13007: 5 room squares round, 3 sides
ZEDQA g14i grid power here true | look dark orange | scale 1.75
ZEDQA g14i machines placed 3
ZEDQA g14i washer: card 840 px, face washer@392
ZEDQA g14i washer: running true
ZEDQA g14i shot g14_ldy_washer
ZEDQA g14i box g14_ldy_washer char 1134,0-1911,735
ZEDQA g14i box g14_ldy_washer world 1929,0-3546,735
ZEDQA g14i box g14_ldy_washer card 2643,46-3483,696
ZEDQA g14i dryer: card 840 px, face dryer@392
ZEDQA g14i shot g14_ldy_dryer
ZEDQA g14i box g14_ldy_dryer char 1134,0-1911,735
ZEDQA g14i box g14_ldy_dryer world 1929,0-3546,735
ZEDQA g14i box g14_ldy_dryer card 2643,46-3483,696
ZEDQA g14i combo: card 840 px, face washer_dryer@392
ZEDQA g14i shot g14_ldy_combo
ZEDQA g14i box g14_ldy_combo char 1134,0-1911,735
ZEDQA g14i box g14_ldy_combo world 1929,0-3546,735
ZEDQA g14i box g14_ldy_combo card 2643,46-3483,696
ERROR: General f:6179> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:129)
    Lua(Vanilla).clearAll(spawnpoints.lua:129)
    Lua(Vanilla).step(spawnpoints.lua:366)
    Lua(Vanilla).tick(spawnpoints.lua:461)
ERROR: General f:6179> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:129)
    Lua(Vanilla).clearAll(spawnpoints.lua:129)
    Lua(Vanilla).step(spawnpoints.lua:366)
    Lua(Vanilla).tick(spawnpoints.lua:461)
ERROR: General f:6179> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:129)
    Lua(Vanilla).clearAll(spawnpoints.lua:129)
    Lua(Vanilla).step(spawnpoints.lua:366)
    Lua(Vanilla).tick(spawnpoints.lua:461)
ZEDQA g14i put back: things taken away, grid and water switches, instant cheat, scale
ERROR: General f:6218 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA g14i back at 925,13040
ZEDQA g14i DONE
```

### 9. gallery_t14_look.lua (`ZEDQA g14l3`) - PASS, 1 s

- go 19151 at 21:55:42

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l3 desk menu bar: Debug left out true
ZEDQA g14l3 position readout and cheat lines off true
ZEDQA g14l3 left-edge column hidden true
ZEDQA g14l3 look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #9 ok=true
ZEDQA g14l3 DONE
```

### 10. gallery_beta_new.lua (`ZEDQA gbn`) - PASS, 21 s

- go 19152 at 21:55:46
- 2 expected exception(s) ignored (expect=)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=42 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gbn start
[ZeD.QA] run #10 ok=true
ZEDQA gbn shot gb_cmap_window
ERROR: General f:7528 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaGalleryErrorOne of non-table: null
ERROR: General f:7528> Lua(Vanilla).boom1> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaGalleryErrorOne of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom1(spawnpoints.lua:56)
ERROR: General f:7588 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaGalleryErrorTwo of non-table: null
ERROR: General f:7588> Lua(Vanilla).boom2> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaGalleryErrorTwo of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom2(spawnpoints.lua:60)
ZEDQA gbn the ZeD wheel: 13 slices, Bug report at 10
ZEDQA gbn shot gb_bugreport_wheel
ZEDQA gbn Bug report: 2 errors copied
ZEDQA gbn shot gb_bugreport_dialog
ZEDQA gbn shot gb_simple_watch
ZEDQA gbn shot gb_simple_belt
ZEDQA gbn shot gb_plain_radio
ZEDQA gbn shot gb_forms_setup
ZEDQA gbn the car's engine running false
ZEDQA gbn shot gb_plain_dash
ZEDQA gbn DONE
```

### 11. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 19153 at 21:56:11

```text
[ZeD.QA] state #11 speed=1 paused=false player=928,13041 grid=19 inCar=false vehicles=31 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
[ZeD.QA] run #11 ok=true
ZEDQA g14e DONE
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
