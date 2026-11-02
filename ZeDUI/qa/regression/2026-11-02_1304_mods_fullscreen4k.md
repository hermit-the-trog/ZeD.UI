# ZeD-UI regression - 2026-11-02 13:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 13:05:03 |
| Finished | 2026-11-02 13:08:56 (3 min 53 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/pl54_hb.txt (3 scripts) |
| Result | **1/3 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 18741 to 18745 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18744, 18745)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_hairbeard_tools.lua | hbt | **FAIL** | 12 | zqa_hbt_none.png, zqa_hbt_razor_in_bag.png, zqa_hbt_scissors.png, zqa_hbt_gel.png, zqa_hbt_spray.png | 1 Java exception(s) in the log; 2 ERR line(s) |
| 3 | zedqa_hairbeard.lua | hb | **FAIL** | 120 | zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_folded.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard_show_all.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_female_heads.png, zqa_hb_female_list.png | 3 Java exception(s) in the log; 10 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 18741 at 13:06:11

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_hairbeard_tools.lua (`ZEDQA hbt`) - FAIL, 12 s

- go 18742 at 13:06:16
- 1 Java exception(s) in the log
- 2 ERR line(s)
- screenshots: zqa_hbt_none.png, zqa_hbt_razor_in_bag.png, zqa_hbt_scissors.png, zqa_hbt_gel.png, zqa_hbt_spray.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hbt start
[ZeD.QA] run #2 ok=true
ZEDQA hbt tools put aside: 0 | female false
ZEDQA hbt none: tools found {} | shave false | cut false | gel style false | spray style false | beard false | rows hair 34 beard 7
ZEDQA hbt PASS none: no tool found
ZEDQA hbt PASS none: no shave, cut or style can be done
ZEDQA hbt PASS none: no beard trim can be done
ZEDQA hbt razor_in_bag: tools found {razor} | shave true | cut false | gel style false | spray style false | beard true | rows hair 34 beard 7
ZEDQA hbt PASS razor in a bag: the razor is found
ZEDQA hbt PASS razor in a bag: a shave can be done
ZEDQA hbt PASS razor in a bag: a cut still needs scissors
ZEDQA hbt PASS razor in a bag: a beard trim can be done
ZEDQA hbt scissors: tools found {scissors} | shave true | cut true | gel style false | spray style false | beard true | rows hair 34 beard 7
ZEDQA hbt PASS scissors: found
ZEDQA hbt PASS scissors: a cut can be done
ZEDQA hbt PASS scissors: a shave can be done (razor or scissors)
ZEDQA hbt gel: tools found {gel,hairdo} | shave false | cut false | gel style true | spray style true | beard false | rows hair 34 beard 7
ZEDQA hbt PASS gel: found (and counts as a hairdo tool)
ZEDQA hbt PASS gel: a gel style can be done
ZEDQA hbt PASS gel: a cut still needs scissors
ZEDQA hbt spray: tools found {spray,hairdo} | shave false | cut false | gel style true | spray style true | beard false | rows hair 34 beard 7
ZEDQA hbt PASS spray: found (and counts as a hairdo tool)
ZEDQA hbt PASS spray: a spray style can be done
ZEDQA hbt PASS a beard trim row can be picked
ERROR: General f:1080> Lua(Vanilla).begin> Exception thrown
    java.lang.NullPointerException: Cannot assign field "callFrame" because "a" is null at ReturnValues.put(ReturnValues.java:61).
    Lua(Vanilla).begin(ISBaseTimedAction.lua:88)
    Lua(Vanilla).addToQueue(ISTimedActionQueue.lua:16)
    Lua(Vanilla).add(ISTimedActionQueue.lua:199)
    Lua((MOD:ZeD-GUI)).add(ZeD_PutBack.lua:152)
    Lua(Vanilla).transferIfNeeded(ISWorldObjectContextMenu.lua:2589)
ZEDQA hbt picked b:Chops: run false | first action ISInventoryTransferAction on IsoPlayer{ Name:null, ID:45 }
ZEDQA hbt FAIL the trim starts the game's action on the player (ISInventoryTransferAction)
ZEDQA hbt put back: 0 tools, the look Grungey /
ZEDQA hbt summary: 16 PASS, 1 FAIL
ZEDQA hbt DONE
```

### 3. zedqa_hairbeard.lua (`ZEDQA hb`) - FAIL, 120 s

- go 18743 at 13:06:31
- 3 Java exception(s) in the log
- 10 ERR line(s)
- screenshots: zqa_hb_list_no_tools.png, zqa_hb_no_tools.png, zqa_hb_tall.png, zqa_hb_greyed_hover.png, zqa_hb_heads_cut.png, zqa_hb_ready.png, zqa_hb_hair_list.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_folded.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard_show_all.png, zqa_hb_pad_beard.png, zqa_hb_beard_cut.png, zqa_hb_beard_list.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_light.png, zqa_hb_female_heads.png, zqa_hb_female_list.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hb start
[ZeD.QA] run #3 ok=true
ERROR: General f:1455> Lua(Vanilla).step> Exception thrown
    java.lang.NullPointerException: Cannot assign field "callFrame" because "a" is null at ReturnValues.put(ReturnValues.java:61).
    Lua(Vanilla).step(spawnpoints.lua:386)
    Lua(Vanilla).tick(spawnpoints.lua:1159)
ZEDQA hb ERR step 1: Cannot assign field "callFrame" because "a" is null java.lang.NullPointerException
ZEDQA hb PASS the Character window is on Identity
ZEDQA hb PASS hair rows from the game's menu: 24
ZEDQA hb groups: tie nil shave 1 cut 18 style 5
ZEDQA hb FAIL Tie and Cut groups
ZEDQA hb PASS a cut with no scissors is greyed with the game's reason: Requires Scissors.
ZEDQA hb FAIL tying needs no tool
ZEDQA hb PASS a style with no gel or spray is greyed: Requires Hair Gel, or Hair Spray.
ZEDQA hb PASS no debug rows
ZEDQA hb PASS Out of reach holds what the hair cannot become: 12
ZEDQA hb PASS the windows are still
ZEDQA hb FAIL timed out: every hair row in view shows its figure, and Now
ZEDQA hb PASS Hidden actions is at Folded (folded)
ZEDQA hb PASS folded: the hint row is there: hb:more:hair
ZEDQA hb PASS folded: the hint row speaks for the hidden verbs (5 kinds): 5 more with the right things
ZEDQA hb PASS folded: no greyed row in the list (0)
ZEDQA hb PASS folded: only the rows the character can do show (0 of 24, 0 can be done)
ZEDQA hb PASS folded: the cut row is not in the list and has no click zone
ZEDQA hb PASS folded: the cut and style rows are no controller stops
ZEDQA hb PASS folded: the hint row is a controller stop (hb:more)
ZEDQA hb PASS folded: the hint row is shut
ZEDQA hb PASS Hide: the hint row is gone
ZEDQA hb PASS hide: no hint row, no greyed row, no stop for them (hide)
ZEDQA hb PASS hide: only the rows the character can do show (0)
ZEDQA hb PASS Show all: the greyed rows show
ZEDQA hb PASS Hidden actions is at Show all (all)
ZEDQA hb PASS show all: no hint row
ZEDQA hb PASS show all: every row shows, Out of reach too (36 of 24 + 12)
ZEDQA hb PASS show all: the rows that cannot be done show greyed (36)
ZEDQA hb PASS show all: the greyed cut row is in the list and a controller stop
ZEDQA hb figures the list: 5 rows in view, 6 figures showing, pool 7
ZEDQA hb PASS the list scrolled: every row in view shows its figure
ZEDQA hb shot zqa_hb_list_no_tools.png
ZEDQA hb rect list_no_tools list 357 111 815 585
ZEDQA hb rect list_no_tools heads 375 -194 779 157
ZEDQA hb PASS no drawn heads and no Pictures window left in the section
ZEDQA hb PASS the figures are a stand-in, not the player's own model
ZEDQA hb PASS a row's figure wears that row's style: Bald -> false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|103246260|2114309842|1202646939|547541912|1774172218|1490752081#Bald/
ZEDQA hb shot zqa_hb_no_tools.png
ZEDQA hb rect no_tools list 357 111 815 585
ZEDQA hb rect no_tools heads 375 181 779 157
ZEDQA hb figures Show all, Out of reach with it: 5 rows in view, 6 figures showing, pool 7
ZEDQA hb PASS figures with Out of reach shown
ZEDQA hb perf list: mean 14.0 ms, 95th 20 ms, worst 38 ms over 240 frames
ZEDQA hb PASS frame time sampled with the list open
ZEDQA hb PASS the tall window is still
ZEDQA hb figures tall window: 16 rows in view, 18 figures showing, pool 18
ZEDQA hb PASS the tall window: every row in view with its figure
ZEDQA hb shot zqa_hb_tall.png
ZEDQA hb rect tall list 357 111 815 1950
ZEDQA hb rect tall heads 375 -194 779 157
ZEDQA hb perf list_tall: mean 17.6 ms, 95th 23 ms, worst 44 ms over 240 frames
ZEDQA hb PASS frame time sampled with the tall window
ZEDQA hb perf tall window: 20 figures showing
ZEDQA hb PASS the window back to its height
ZEDQA hb PASS the real character is unchanged while the figures show (Grungey||nil|103246260|2114309842|1202646939|547541912|1774172218|1490752081)
ZEDQA hb tab for the release check: loot
ZEDQA hb PASS another tab: the figures leave the window (pool 0, children 0)
ZEDQA hb perf other_tab: mean 8.9 ms, 95th 17 ms, worst 21 ms over 240 frames
ZEDQA hb PASS frame time sampled on another tab
ZEDQA hb perf the figures cost 5.1 ms a frame on the mean (list 14.0, other tab 8.9)
ZEDQA hb perf tall window costs 8.7 ms a frame on the mean (17.6)
ZEDQA hb FAIL timed out: back on Identity, the figures come back
ZEDQA hb PASS folded: the hint row has a click zone
ZEDQA hb PASS folded: the cut row has no click zone (it is under the hint row)
ZEDQA hb PASS a click on the hint row opens it
ZEDQA hb PASS opened: the greyed rows show under the hint row
ZEDQA hb PASS opened: the hint row keeps its place and every hidden row follows it (36 of 24 + 12)
ZEDQA hb PASS opened: the greyed cut row is there, a controller stop
ZEDQA hb PASS opened: the hint row is in view with its click zone (the fold stays open until shut: HB.onClick -> DS.toggle)
ZEDQA hb PASS a second click shuts the hint row
ZEDQA hb PASS shut: the greyed rows go again
ZEDQA hb PASS Show all: the greyed rows show again
ZEDQA hb PASS show all: the cut row has a click zone
ZEDQA hb PASS a click picks the row
ZEDQA hb PASS the mouse is over a row (its hint shows)
ZEDQA hb shot zqa_hb_greyed_hover.png
ZEDQA hb PASS Cut (beside the Hair | Beard switch) is greyed for a greyed row
ZEDQA hb PASS pressing the greyed button does nothing
ZEDQA hb PASS Folded again: the greyed rows are gone
ZEDQA hb PASS with scissors the cut can be done: Cut Hair into Short
ZEDQA hb head item: Baseball Cap
ZEDQA hb figures scissors and a cap: 1 rows in view, 4 figures showing, pool 7
ZEDQA hb PASS every row in view with its figure, and the Now / After heads
ZEDQA hb PASS the After head wears the picked style: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|103246260|311269212|2114309842|1202646939|547541912|1774172218|1490752081#Short/
ZEDQA hb PASS the Now head wears the hair now: false|2|MaleBody03|0.584,0.251,0.251|0.584,0.251,0.251|-1|103246260|311269212|2114309842|1202646939|547541912|1774172218|1490752081#Grungey/
ZEDQA hb PASS the cap is still on the real character (only the figures go without it)
ZEDQA hb PASS the heads half out of the view: Now and After show the part inside it
ZEDQA hb PASS hair: Now and After cut by the view's edge, not left empty (cut 64.78125 px)
ZEDQA hb shot zqa_hb_heads_cut.png
ZEDQA hb rect heads_cut list 357 111 815 585
ZEDQA hb rect heads_cut heads 375 45 779 157
ZEDQA hb shot zqa_hb_ready.png
ZEDQA hb rect ready list 357 111 815 585
ZEDQA hb rect ready heads 375 181 779 157
ZEDQA hb figures with scissors: 5 rows in view, 6 figures showing, pool 7
ZEDQA hb PASS with scissors, the list: every row in view with its figure
ZEDQA hb shot zqa_hb_hair_list.png
ZEDQA hb rect hair_list list 357 111 815 585
ZEDQA hb rect hair_list heads 375 -194 779 157
ZEDQA hb PASS Cut is live
ERROR: General f:5111> Lua(Vanilla).begin> Exception thrown
    java.lang.NullPointerException: Cannot assign field "callFrame" because "a" is null at ReturnValues.put(ReturnValues.java:61).
    Lua(Vanilla).begin(ISBaseTimedAction.lua:88)
    Lua(Vanilla).addToQueue(ISTimedActionQueue.lua:16)
    Lua(Vanilla).add(ISTimedActionQueue.lua:199)
    Lua((MOD:ZeD-GUI)).add(ZeD_PutBack.lua:152)
    Lua((MOD:ZeD-GUI)).cutHair(ZeD_HairBeard.lua:145)
ZEDQA hb FAIL the cut is running
ZEDQA hb FAIL the game's ISCutHair is queued
ZEDQA hb shot zqa_hb_cutting.png
ZEDQA hb PASS the cut ends
ZEDQA hb FAIL the hair is now Short: Grungey
ZEDQA hb FAIL the line under the switch says done: nil
ZEDQA hb PASS the cap came off first
ZEDQA hb FAIL the license's Hair style line follows: Grungey
ZEDQA hb shot zqa_hb_done.png
ZEDQA hb PASS a tie row after growing it back
ZEDQA hb PASS the tie row is a controller stop
ERROR: General f:5294> Lua(Vanilla).begin> Exception thrown
    java.lang.NullPointerException: Cannot assign field "callFrame" because "a" is null at ReturnValues.put(ReturnValues.java:61).
    Lua(Vanilla).begin(ISBaseTimedAction.lua:88)
    Lua(Vanilla).addToQueue(ISTimedActionQueue.lua:16)
    Lua(Vanilla).add(ISTimedActionQueue.lua:199)
    Lua((MOD:ZeD-GUI)).add(ZeD_PutBack.lua:152)
    Lua((MOD:ZeD-GUI)).cutHair(ZeD_HairBeard.lua:157)
ZEDQA hb PASS the tie ends
ZEDQA hb PASS tied: the loose style is kept (Fabian)
ZEDQA hb PASS tied: Untie Hair is the only row (1)
ZEDQA hb shot zqa_hb_tied.png
ZEDQA hb PASS the untie ends
ZEDQA hb PASS untied: back to Fabian (Fabian)
ZEDQA hb PASS focus on the tab's disclosure
ZEDQA hb PASS down from the disclosure lands on the Hair | Beard switch (hb:part)
ZEDQA hb PASS Cut is a stop right after the Hair | Beard switch (1, 2)
ZEDQA hb PASS Cut's stop sits exactly on its button, at the top (stop 691.35546875,593.15234375 105.64453125x46, button 691.35546875,593.15234375 105.64453125x46)
ZEDQA hb PASS Cut is a stop with the list scrolled down
ZEDQA hb PASS Cut's stop sits exactly on its button, scrolled down (stop 691.35546875,-1908.84765625 105.64453125x46, button 691.35546875,-1908.84765625 105.64453125x46)
ZEDQA hb PASS focusing Cut scrolls it into view
ZEDQA hb PASS Cut's stop sits exactly on its button, after the scroll to it (stop 691.35546875,76.15234375 105.64453125x46, button 691.35546875,76.15234375 105.64453125x46)
ZEDQA hb PASS right flips to Beard and stays on the switch
ZEDQA hb PASS folded: down from the switch lands on the hint row (hb:more)
ZEDQA hb PASS folded: focus on the hint row picks nothing (nil)
ZEDQA hb PASS folded: no beard row can be done, only the hint row shows (0 rows)
ZEDQA hb shot zqa_hb_pad_beard_folded.png
ZEDQA hb PASS folded: A on the hint row opens it
ZEDQA hb PASS opened: the greyed beard rows show under the hint row
ZEDQA hb PASS opened: down walks into the beard rows (hb:row:b:)
ZEDQA hb PASS opened: the strip follows focus with no press
ZEDQA hb PASS opened: greyed with the game's reason: Requires a Razor or Scissors.
ZEDQA hb PASS opened: A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_greyed.png
ZEDQA hb PASS opened: the hint row is a stop
ZEDQA hb PASS A on the hint row shuts it
ZEDQA hb PASS shut: the greyed beard rows go again
ZEDQA hb PASS Show all: the greyed beard rows show
ZEDQA hb PASS show all: no hint row to walk through
ZEDQA hb PASS show all: down walks into the beard rows (hb:row:b:)
ZEDQA hb PASS show all: the strip follows focus with no press
ZEDQA hb PASS show all: greyed with the game's reason: Requires a Razor or Scissors.
ZEDQA hb PASS show all: A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_show_all.png
ZEDQA hb PASS Folded again: the greyed beard rows are gone
ZEDQA hb PASS with scissors the trim can be done: Trim Beard into Mustache
ZEDQA hb figures beard: 3 rows in view, 4 figures showing, pool 7
ZEDQA hb figures beard: 1 rows in view, 4 figures showing, pool 7
ZEDQA hb PASS every beard row in view with its figure, and the Now / After heads
ZEDQA hb PASS the beard list runs on the character's own hair: Grungey
ZEDQA hb PASS beard, under the heads: every beard row's figure keeps the character's hair (Grungey, 1 rows)
ZEDQA hb PASS beard, under the heads: every beard row's figure wears that row's beard (1 rows)
ZEDQA hb PASS beard: Now shows the character as they are: #Grungey/Full@S
ZEDQA hb PASS the focused row is the picked one (b:Moustache)
ZEDQA hb PASS beard: After shows the picked row's result: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_pad_beard.png
ZEDQA hb rect pad_beard list 357 111 815 585
ZEDQA hb rect pad_beard heads 375 181 779 157
ZEDQA hb PASS beard: the heads half out of the view, Now and After show the part inside it
ZEDQA hb PASS beard: Now and After cut by the view's edge, not left empty
ZEDQA hb shot zqa_hb_beard_cut.png
ZEDQA hb rect beard_cut list 357 111 815 585
ZEDQA hb rect beard_cut heads 375 45 779 157
ZEDQA hb fig b: y 389 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 511 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig after y 111 h 66 cut 64 zoom 20.956 yoff -0.7726
ZEDQA hb fig now y 111 h 66 cut 64 zoom 20.956 yoff -0.7726
ZEDQA hb fig b:Moustache y 607 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb figures beard rows: 5 rows in view, 6 figures showing, pool 7
ZEDQA hb PASS beard: the list scrolled, every row in view with its figure
ZEDQA hb PASS beard, the list: every beard row's figure keeps the character's hair (Grungey, 5 rows)
ZEDQA hb PASS beard, the list: every beard row's figure wears that row's beard (5 rows)
ZEDQA hb PASS the picked beard row's figure wears that beard: #Grungey/Moustache@S
ZEDQA hb shot zqa_hb_beard_list.png
ZEDQA hb rect beard_list list 357 111 815 585
ZEDQA hb rect beard_list heads 375 -194 779 157
ZEDQA hb fig b: y 149 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chops y 271 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Moustache y 367 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Goatee y 463 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:BeardOnly y 559 h 72 cut 0 zoom 18.500 yoff -0.8300
ZEDQA hb fig b:Chin y 655 h 40 cut 31 zoom 21.339 yoff -0.8927
ZEDQA hb PASS the trim ends
ZEDQA hb PASS the beard is now Moustache: Moustache
ZEDQA hb PASS the hint row alone, shut
ZEDQA hb PASS the hint row names the styles out of reach: choose from more styles
ZEDQA hb PASS Out of reach is a stop (the hint row, hb:more)
ZEDQA hb PASS A folds Out of reach open (the hint row opens)
ZEDQA hb PASS an out-of-reach row can be focused and says why
ZEDQA hb shot zqa_hb_out_of_reach.png
ZEDQA hb PASS a trait is a controller stop: identity:trait:Dextrous
ZEDQA hb PASS focus shows the description at once (no hover timer): Dextrous
ZEDQA hb shot zqa_hb_trait_focus.png
ZEDQA hb PASS trait zones are kept for hover
ZEDQA hb PASS hover on a trait shows its description: Dextrous
ZEDQA hb PASS the trait's card is drawn after the shared pause
ZEDQA hb shot zqa_hb_trait_hover.png
ZEDQA hb figures Large text: 4 rows in view, 5 figures showing, pool 7
ZEDQA hb PASS Large text: every row in view with its figure
ZEDQA hb shot zqa_hb_large.png
ZEDQA hb rect large list 240 127 938 564
ZEDQA hb rect large heads 260 -226 898 183
ZEDQA hb figures Light: 1 rows in view, 3 figures showing, pool 7
ZEDQA hb PASS Light: every row in view with its figure
ZEDQA hb shot zqa_hb_light.png
ZEDQA hb rect light list 357 111 815 585
ZEDQA hb rect light heads 375 -194 779 157
ZEDQA hb Spongie's Hairstyle Unlocker on: false
ZEDQA hb PASS no Traits tab without Traits As Skills
ZEDQA hb figures after Large and Light: 5 rows in view, 6 figures showing, pool 7
ZEDQA hb PASS every row in view with its figure
ZEDQA hb PASS Spongie's tagged row in view with its figure
ZEDQA hb PASS the window closed: the figures left it (children 0)
ZEDQA hb figures reopened: 1 rows in view, 3 figures showing, pool 3
ZEDQA hb PASS reopened: the figures come back
ZEDQA hb made a woman for the check: true, skin FemaleBody03
ZEDQA hb figures a woman: 2 rows in view, 4 figures showing, pool 4
ZEDQA hb PASS a woman: her hair rows and Now show
ZEDQA hb PASS a woman: no beard half (0 beard rows)
ZEDQA hb PASS a woman: the figures' stand-in is a woman
ZEDQA hb PASS a woman: every row is one of the game's women's styles (39 rows)
ZEDQA hb PASS a woman: Now wears her hair: #Long2/
ZEDQA hb PASS a woman: After shows the picked cut
ZEDQA hb PASS a woman: After wears the picked cut: #Bob/
ZEDQA hb shot zqa_hb_female_heads.png
ZEDQA hb rect female_heads list 357 111 815 585
ZEDQA hb rect female_heads heads 375 181 779 157
ZEDQA hb figures a woman's list: 5 rows in view, 6 figures showing, pool 6
ZEDQA hb PASS a woman's list: every row in view with its figure
ZEDQA hb shot zqa_hb_female_list.png
ZEDQA hb rect female_list list 357 111 815 585
ZEDQA hb rect female_list heads 375 -194 779 157
ZEDQA hb PASS the QA character is put back: female false, skin MaleBody03
ZEDQA hb put back: Grungey / , 0 tools returned
ZEDQA hb PASS Hidden actions is back as it was found: 1 (was 1)
ZEDQA hb 10 failed
ZEDQA hb DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
