# ZeD-UI regression - 2026-11-18 18:06 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-18 18:06:48 |
| Finished | 2026-11-18 18:09:12 (2 min 23 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_hud_only.txt (3 scripts) |
| Result | **2/3 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 29973 to 29977 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29976, 29977)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_hud.lua | rt_hud | **FAIL** | 45 |  | 2 ERR line(s); its own checks failed (VERDICT FAIL) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29973 at 18:07:53

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
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 29974 at 18:07:58

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_hud.lua (`ZEDQA rt_hud`) - FAIL, 45 s

- go 29975 at 18:08:02
- 2 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_hud start (125 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_hud PASS safe mode is off, so ZeD draws the HUD
ZEDQA rt_hud PASS every HUD module is loaded
ZEDQA rt_hud PASS window alone: toggle opens the Character window without the World window
ZEDQA rt_hud PASS window alone: it opens on Loot with the drawer shut | loot, drawer false
ZEDQA rt_hud PASS on screen (the Character window alone): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS window alone: toggle again closes it
ZEDQA rt_hud PASS UI scale Auto: ZeD.Scale is loaded
ZEDQA rt_hud PASS UI scale Auto: the root is the screen height over 1080, held to 0.75 .. 4, times the font knob | 2, want 2 at 2160 px high
ZEDQA rt_hud PASS belt: drawn
ZEDQA rt_hud PASS belt: at the bottom of the screen | 1535,2034 662x98
ZEDQA rt_hud PASS belt: the game's hotbar is parked off screen (Overrides/Belt.lua)
ZEDQA rt_hud PASS belt: the game's left column shows no hands and no window buttons | column up; showing:
ZEDQA rt_hud PASS hands: two circles, the main hand the bigger | 98 and 77
ZEDQA rt_hud PASS hands: the off hand left of the main hand (seen from behind)
ZEDQA rt_hud PASS on screen (belt): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS hands: one item in both hands slides the off hand under the main hand
ZEDQA rt_hud PASS hands: one hand free again, the off hand back beside the main hand
ZEDQA rt_hud PASS belt menu: the hammer is in the main hand
ZEDQA rt_hud PASS belt menu: the belt takes a right-click on the main hand
ZEDQA rt_hud PASS belt menu, right-click on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, right-click on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, right-click on the main hand): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS belt menu: it holds the hammer's own options | 12
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on the main hand): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS belt menu: the pad's menu names the belt its origin (the way back to it)
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on a slot): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS belt: a number key held past half a second opens its slot's list
ZEDQA rt_hud PASS belt: the slot's list opens at its slot, on screen | 0,0 3840x2160, slot at x 1798
ZEDQA rt_hud PASS on screen (the slot's list): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS belt: the key's release after the list draws nothing
ZEDQA rt_hud FAIL belt: the Messages note is on the belt
ZEDQA rt_hud PASS simple belt: the Belt option's Simple is read
ZEDQA rt_hud PASS simple belt: no strap and no buckle
ZEDQA rt_hud PASS simple belt: the slots SIMPLE_GAP apart | 11 px, want 11
ZEDQA rt_hud PASS simple belt: on screen
ZEDQA rt_hud PASS on screen (simple belt): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS simple belt: Full brings the strap back
ZEDQA rt_hud PASS watch: the worn watch is on the belt | Base.WristWatch_Left_DigitalBlack
ZEDQA rt_hud PASS watch: the mini sits beside its own hand (left wrist)
ZEDQA rt_hud PASS watch: the full watch is tucked away while the mini shows
ZEDQA rt_hud PASS watch: the middle of the mini is its face | face
ZEDQA rt_hud PASS watch: the face opens the full watch | 248x352
ZEDQA rt_hud PASS watch: the full watch stands above the mini on the belt | 2023 over 2037
ZEDQA rt_hud PASS on screen (full watch): every ZeD window and pop-up inside 3840x2160 | 4 seen
ZEDQA rt_hud PASS watch: a second press tucks it back
ZEDQA rt_hud PASS watch: its light comes on | no light spot on the mini: the watch's own light control
ZEDQA rt_hud PASS action bar: a bag to pack
ZEDQA rt_hud PASS action bar: the game's timed action is drawn
ZEDQA rt_hud PASS action bar: it names the action | MOVING PENCIL
ZEDQA rt_hud PASS action bar: the queue count reads the moves queued | qi 0 of 4, queued 4
ZEDQA rt_hud PASS action bar: its layer shows
ZEDQA rt_hud PASS on screen (action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS action bar: the bar follows the action | 0.00 to 0.10
ZEDQA rt_hud PASS action bar: the job ends with Done drawn from it
ZEDQA rt_hud PASS action bar: the Done fades and the bar clears
ZEDQA rt_hud PASS action bar: the action did its work (4 in the bag)
ZEDQA rt_hud PASS bar style: Simple draws the simple bar | simple
ZEDQA rt_hud PASS bar style: the simple bar is 53 x 9 units | 53 x 9
ZEDQA rt_hud PASS bar style: the simple bar is on screen | 1867,987 106x18
ZEDQA rt_hud PASS bar style: the simple bar stands above the head | 1005 over 1017.40625
ZEDQA rt_hud PASS on screen (simple action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the simple job ends
ZEDQA rt_hud PASS bar style: Detailed draws the thought bubble | verbose
ZEDQA rt_hud PASS bar style: the detailed bar has its size | 64 x 30
ZEDQA rt_hud PASS bar style: the detailed bar is on screen | 1858,909 152x104
ZEDQA rt_hud PASS on screen (detailed action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the detailed job ends
ZEDQA rt_hud PASS no bar: the attach starts
ZEDQA rt_hud PASS no bar: the game's own flag is read (useProgressBar false, _zedBar false)
ZEDQA rt_hud PASS no bar: the action bar has no state for it
ZEDQA rt_hud PASS right: the moodles are placed right | right
ZEDQA rt_hud PASS right: at least three moodles are on | 5
ZEDQA rt_hud PASS right: every moodle is on screen | 3782,940 48x280
ZEDQA rt_hud PASS right: the column is at the right edge | 3782
ZEDQA rt_hud PASS on screen (moodles right): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS left: the moodles are placed left | left
ZEDQA rt_hud PASS left: at least three moodles are on | 5
ZEDQA rt_hud PASS left: every moodle is on screen | 10,940 48x280
ZEDQA rt_hud PASS left: the column is at the left edge | 10
ZEDQA rt_hud PASS on screen (moodles left): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bottom: the moodles are placed bottom | bottom
ZEDQA rt_hud PASS bottom: at least three moodles are on | 5
ZEDQA rt_hud PASS bottom: every moodle is on screen | 1780,1965 280x48
ZEDQA rt_hud PASS bottom: the row is centred
ZEDQA rt_hud PASS bottom: the row sits above the belt
ZEDQA rt_hud PASS bottom: the game's column is out of sight (no double)
ZEDQA rt_hud PASS on screen (moodles bottom): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: a line the character says is in ZeD's balloon
ZEDQA rt_hud PASS bubble: the over-head layer draws it
ZEDQA rt_hud PASS on screen (speech bubble): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: it fades and goes
ZEDQA rt_hud PASS xp: Perks.Woodwork exists in this build
ZEDQA rt_hud PASS xp: skill XP goes through with ZeD on, no error
ZEDQA rt_hud PASS xp: the gain is logged in Messages | Carpentry +1.2 XP
ZEDQA rt_hud PASS xp: a game note goes to ZeD's bubble, marked good
ZEDQA rt_hud PASS xp: the over-head layer draws the note
ZEDQA rt_hud PASS on screen (over-head note): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS xp: the note fades and goes
ZEDQA rt_hud PASS guide: a fresh machine arms the bubble
ZEDQA rt_hud PASS guide: the bubble comes out
ZEDQA rt_hud PASS guide: the guide's own words | New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time.
ZEDQA rt_hud PASS guide: a long bare balloon for player one
ZEDQA rt_hud PASS guide: it comes out of the belt's Messages note
ZEDQA rt_hud PASS on screen (guide bubble): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS guide: the bubble goes by itself
ZEDQA rt_hud PASS guide: its line stays in Messages
ZEDQA rt_hud SKIP hint strip at a door (no door within 12 tiles on this floor)
ZEDQA rt_hud PASS forage: ZeD's pin and pointer are loaded
ZEDQA rt_hud PASS forage: search mode is on
ZEDQA rt_hud NOTE forage: 0 things earlier runs left on the ground by the home taken away
ZEDQA rt_hud PASS forage: a find is staged | Base.MushroomGeneric1
ZEDQA rt_hud PASS forage: a pinned find's pointer is empty (its pin marks it) | zed_forage_hand_none
ZEDQA rt_hud PASS forage: the pointer to the find is up | a find in sight, not spotted yet: true
ZEDQA rt_hud PASS forage: the pointer is ZeD's hand for the find's side | zed_forage_hand_up_a
ZEDQA rt_hud PASS forage: the hand is its set size | 36 x 63, want 36 x 63
ZEDQA rt_hud PASS forage: white at its set alpha | alpha 0.4000000059604645, want 0.4
ZEDQA rt_hud PASS forage: the pin over the find is ZeD's magnifying glass | 176 of 215 draws
ZEDQA rt_hud PASS forage: the search-mode eye is in ZeD's over-head stack
ZEDQA rt_hud PASS forage pointer: a find on the ground shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud SKIP forage pointer: a stash find shows ZeD's hand (the game draws no pointer to a stash (ISBaseIcon:updateWorldMarker skips iconClass stashObject))
ZEDQA rt_hud PASS forage pointer: an animal track shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud PASS on screen (forage): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS forage: the find and its pointer are gone again
ZEDQA rt_hud PASS forage tab: the World window's Foraging tab opens from the strip
ZEDQA rt_hud PASS forage tab: the band draws its Search button
ZEDQA rt_hud PASS forage tab: a click on Search flips the game's search mode | true
ZEDQA rt_hud PASS forage tab: a second click puts search mode back
ZEDQA rt_hud PASS balloon: it shows | rtqa:a
ZEDQA rt_hud PASS balloon: near the screen's corner it stays fully on screen | 3454,2015 350x80
ZEDQA rt_hud PASS balloon: one at a time (a second one asked while it is up does not draw) | up: rtqa:a
ZEDQA rt_hud PASS balloon: dismissed, it stays down while its control still asks
ZEDQA rt_hud PASS balloon: the focus on another control brings a balloon back
ZEDQA rt_hud PASS paused: the Character window is open
ZEDQA rt_hud PASS paused: the game reads paused
ZEDQA rt_hud PASS paused: the glass lies on the Character window
ZEDQA rt_hud PASS paused: the glass covers the item list
ZEDQA rt_hud PASS paused: the glass takes a press and a right press (nothing is used)
ZEDQA rt_hud PASS paused: the pad's A and X are held outside the tab strip and the bags | no live zone
ZEDQA rt_hud PASS on screen (paused Character window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS paused: the tab strip still switches tabs | equip, want equip
ZEDQA rt_hud PASS paused: playing again, the glass is gone
ZEDQA rt_hud PASS pin: the Skills tab opens from the strip
ZEDQA rt_hud PASS pin: the Skills tab draws its skill rows
ZEDQA rt_hud PASS pin: a right-click on the skill row opens its menu
ZEDQA rt_hud PASS on screen (skill row menu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS pin: the menu offers Pin to title bar
ZEDQA rt_hud PASS pin: the skill is pinned | Aiming
ZEDQA rt_hud PASS pin: the title bar shows its level and XP | 0/75 in: Long Blade - Lv.0 - 0/75 | Aiming - Lv.0 - 0/75 | 28.4 / 15 kg
ZEDQA rt_hud PASS pin item: four pinnable things to pin | 4 of 4
ZEDQA rt_hud PASS pin item: the item's own menu offers Pin to title bar
ZEDQA rt_hud PASS pin item: the pick puts the item's kind and id in ZeD_Pins | cond 127238303
ZEDQA rt_hud PASS pin item: ZeD.Pins.stats gives its row | Claw Hammer | 10/10
ZEDQA rt_hud PASS pin item: the Character window's title bar shows it | Claw in: Claw Hammer | 10/10 | 36.9 / 15 kg
ZEDQA rt_hud PASS pins: a fourth pin takes off the oldest (three at most) | 3 pins
ZEDQA rt_hud PASS pins: a note over the head says which pin went | Firefighter Axe pinned. Claw Hammer was taken off (3 at most).
ZEDQA rt_hud PASS popclear: a ZeD window is open to keep clear of
ZEDQA rt_hud PASS popclear: a pop-out over a ZeD window moves clear of it, on screen | 2265,367 to 2265,749
ZEDQA rt_hud PASS popclear: a spot clear of the windows is kept | 0,0 to 0,0
ZEDQA rt_hud PASS prompt: the game's ISTextBox is ZeD's text prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the text prompt shows
ZEDQA rt_hud PASS prompt: the text prompt is on screen
ZEDQA rt_hud PASS on screen (text prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the text prompt has its OK
ZEDQA rt_hud PASS prompt: OK hands the typed text back in entry | OK ZeD QA typed
ZEDQA rt_hud PASS prompt: the text prompt closes on OK
ZEDQA rt_hud PASS prompt: the game's ISModalRichText is ZeD's rich prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the rich prompt shows
ZEDQA rt_hud PASS prompt: the long rich text stays on screen | 1537,616 770x930 on 3840x2160
ZEDQA rt_hud PASS prompt: the long text scrolls inside it instead of growing past the screen | 1889.390625
ZEDQA rt_hud PASS on screen (rich prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the rich prompt has its OK
ZEDQA rt_hud PASS prompt: OK answers and closes the rich prompt
ZEDQA rt_hud PASS prompt: the game's ISModalDialog is ZeD's question
ZEDQA rt_hud PASS prompt: the question is the prompt on top
ZEDQA rt_hud PASS prompt: Escape answers No on the prompt on top | NO
ZEDQA rt_hud PASS prompt: that Escape does not open the pause menu
ZEDQA rt_hud PASS prompt: the second question is the prompt on top
ZEDQA rt_hud PASS prompt: Enter presses the main answer (Yes) | YES
ZEDQA rt_hud SKIP the mini-map stays hidden (the game made no mini-map for this player)
ZEDQA rt_hud PASS run-sneak: the module and its setting are loaded
ZEDQA rt_hud PASS run-sneak: Run held 400 ms standing still crouches | crouch
ZEDQA rt_hud PASS run-sneak: held again, it stands | stand
ZEDQA rt_hud PASS put back: the character where it started
ZEDQA rt_hud PASS put back: the moodles' place
ZEDQA rt_hud PASS put back: the watch's place
ZEDQA rt_hud end: 184 pass, 1 fail, 3 skipped
ZEDQA rt_hud VERDICT FAIL 1
ZEDQA rt_hud DONE
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
