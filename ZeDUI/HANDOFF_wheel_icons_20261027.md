# Handoff to Code: the wheels' icons (Oct 27 2026)

Approved by the director on Oct 27. He asked for them with "we need new icons for the radial wheels." and set the scope: ZeD's wheels and vanilla's too ("ZeD + vanilla's too": vanilla's emotes, firearm steps, zoom, speed and light pictures redrawn as well), "Ink + pictogram figures", both sizes drawn (16 at rest, 24 when pointed), and the same icons for the context strip later. On the figures he wrote "Figures need some looping refinement. The figures might need more pixels to look right or need to follow a template or doll", then, on the template, "Love them. They are just rough enough to still be clear." On the whole set he sent eight notes (the run read as yoga, the car seat's base, the wrench's hex, the small bandage, the key's teeth, arms on the follow figures, the big thumbs, the clap). On the second round: "Nailed it".

## Where things are
- **Textures:** `42/media/textures/ZeD/wheel/<size>/<id>.png`, 151 icons in four sizes (604 files):
  - `16/` and `24/` hold the two drawings, pixel for pixel;
  - `32/` and `48/` hold the same drawings doubled, each pixel 2 x 2, for 2x.
  - They're white on clear, and alpha is only ever 0 or 255.
- **The map:** `ZeDUI/mockups/zed_wheel_icons_v1/wheel_icons_map.json`. It holds every icon (its group, what it means, whether a wheel uses it yet) and every rule in section 3, as data.
- **Review sheets** (`ZeDUI/mockups/zed_wheel_icons_v1/`):
  - `review_rings.png` shows the wheels as they'd look in game, at 3x;
  - `review_catalogue_1.png` to `review_catalogue_3.png` show every icon by its id, at both sizes;
  - `review_true_size.png` shows the whole set at 1x;
  - `review_round2_before_after.png` and `review_round2_rings.png` show the eight notes, before and after.
- **Source:** `ZeDUI/tools/wheelpx/` (see its README). `python export.py` rebuilds the textures and the map.

## 1. What changes
Every slice on every wheel ZeD draws shows one of these icons. That covers ZeD's D-pad wheels, and the vanilla radials ZeD_Wheel draws in their place: vehicle, firearm, light source, animal, emotes, the back button's wheel, the hotbar and the stick click.

- **Three kinds keep their own pictures:** items, traits, and the controller's button glyphs.
- **The Back slice** keeps the strip's own back glyph (`W.isBack`, as now).
- **Leaving the KEEP list:** the vanilla pictures ZeD_Wheel has kept until now (the emotes, the firearm's steps, zoom, game speed, the batteries) are redrawn here.

## 2. Drawing an icon
- **Tint:** as today. Each icon is a white shape (`iconTintable`):
  - ink on the paper cell at rest;
  - `T.textOnAccent` on the accent when pointed;
  - 0.45 alpha when the slice is off.
- **Size:** the cell's icon box is `T.px(16)` at rest and `T.px(24)` when pointed.
  - Draw the largest of the four sizes that fits the box, at its own size, centred (floor).
  - Don't stretch it to the box and don't filter it: these are drawn pixel for pixel.

  | UI scale | At rest: box, drawn | Pointed: box, drawn |
  |---|---|---|
  | 0.5x | 8, the 16 scaled down | 12, the 16 scaled down |
  | 0.75x | 12, the 16 scaled down | 18, `16` |
  | 1x | 16, `16` | 24, `24` |
  | 1.25x | 20, `16` | 30, `24` |
  | 1.5x | 24, `24` | 36, `32` |
  | 1.75x | 28, `24` | 42, `32` |
  | 2x | 32, `32` | 48, `48` |

  Auto scale follows the same rule. Only a box under 16 scales a picture, down, the old way.
- **The slice carries the id, not a texture.** Pick the texture when the cell is drawn, by its box, and cache it by path.

## 3. Which icon goes where
### 3a. ZeD's own wheels (`ZeD_DpadWheels.lua`)
Each slice names an icon (`icon =`), a tab icon (`tab =`), or a vanilla picture (`vanilla =`, `tex =`). Have it name the new id instead. Where one old name stood for two things, the slice decides. For example, `eye` was both search mode on and hide the interface.

| Wheel | Slice (its words' key) | Names now | New id |
|---|---|---|---|
| character | `UI_ZeD_Wheel_Tabs` | `tab loot-tab-white` | `crate` |
| character | `UI_ZeD_Wheel_Weapons` | `knife` | `knife` |
| character | `ContextMenu_Eat` | `apple-whole` | `apple` |
| character | `ContextMenu_Drink` | `water-045-drink` | `glass` |
| character | `UI_ZeD_Wheel_Medicine` | `bandage-wound` | `medkit` |
| character | `ContextMenu_Sleep` | `bed` | `bed` |
| character | `UI_ZeD_Wheel_Clothing` | `fi-br-shirt-long-sleeve` | `shirt` |
| character | `UI_ZeD_Wheel_Use` | `backpack` | `backpack` |
| character > Weapons | `UI_ZeD_Wheel_HandsFree` | `backpack` | `hand` |
| character > Medicine | the wounds (H.treatments' entries) | `bandage-wound` | `bandage` |
| character > Medicine, Clothing, Radio | the tab slices (Health, Equipment, Radio) | `tab health- / equipment- / radio-tab-white` | `heart / jacket / walkie` |
| character > Use | `ContextMenu_Smoke` | `smoking` | `cigarette` |
| character > Use | `ContextMenu_Read` | `book-open-reader` | `book` |
| character > Use | `UI_ZeD_Wheel_Watch` | `clock` | `watch` |
| character > Use | `IGUI_ItemType_Radio` | `survival-077-radio` | `walkie` |
| character > Watch | `UI_ZeD_Wheel_OpenWatch` | `clock` | `watch` |
| character > Watch | `UI_ZeD_Wheel_WatchLight` | `lightbulb-on` | `bulb_on` |
| character > Watch | `UI_ZeD_Wheel_WatchAlarm` | `essential-collection-213-alarm` | `alarm` |
| character > Radio | `UI_ZeD_Wheel_NextStation` | `fm-radio` | `seek` |
| world | `UI_ZeD_Wheel_Tabs` | `tab craft-tab-white` | `craft` |
| world | `UI_ZeD_Wheel_Map` | `crafting-game-037-map` | `map` |
| world | `UI_ZeD_Wheel_Vehicle` | `car-mechanic` | `car` |
| world | `UI_ZeD_Wheel_Animal` | `cow` | `cow` |
| world | `UI_ZeD_Wheel_CraftBuild` | `carpentry-015-toolbox` | `toolbox` |
| world | `UI_ZeD_Wheel_Search` | `fi-br-magnifying-glass-wave` | `magnifier` |
| world | `UI_ZeD_Wheel_LightsPower` | `lightbulb-on` | `bulb_on` |
| world | `IGUI_Zone_Name` | `map-marker` | `fence` |
| world | `IGUI_Emote_Shout` | `bullhorn` | `bullhorn` |
| world (server) | `UI_ZeD_Wheel_Chat` | `text-box-dots` | `chat` |
| world (server) | `UI_ZeD_Wheel_Safety` | `fi-br-lock` | `padlock` |
| world (server) | `UI_ZeD_Wheel_Players` | `handshake` | `group` |
| world > Map | `IGUI_WorldMap_Toggle` | `crafting-game-037-map` | `map` |
| world > Map | `IGUI_MiniMap_Toggle` | `fi-br-map-point` | `minimap` |
| world > Map | `IGUI_MiniMap_Focus` | `map-marker` | `pin` |
| world > Craft and build | `IGUI_CraftingWindow_Title` | `tab craft-tab-white` | `craft` |
| world > Craft and build | `UI_ZeD_World_TabBuilding` | `tab build-tab-white` | `bricks` |
| world > Craft and build | `IGUI_BackButton_Movable` | `tab move-tab-white` | `chair` |
| world > Search | `UI_enable_search_mode` | `eye` | `eye` |
| world > Search | `UI_disable_search_mode` | `eye` | `eye_off` |
| world > Search | `UI_investigate_area_window_show` | `tab forage-tab-white` | `magnifier` |
| world > Search | `IGUI_Pickup` | `fi-br-picking-box` | `box_up` |
| world > Lights and power | `UI_ZeD_Wheel_RoomLights` | `lightbulb-on` | `bulb_on` |
| world > Lights and power | `ContextMenu_Generator` | `doomsday-007-generator` | `generator` |
| world > Lights and power | ContextMenu_Light_fire / ContextMenu_Put_out_fire | `campfire` | `campfire` |
| world > Vehicle | `IGUI_VehiclePartCatdashboard` | `fuel-gauge` | `gauge` |
| stance | `UI_ZeD_Wheel_Sit` | `sitting-ground` | `sit_ground` |
| stance | `UI_ZeD_Wheel_Crouch` | `emotes/crouch_on / crouch_off` | `sneak / sneak_off` |
| stance | `UI_ZeD_Wheel_AutoWalk` | `emotes/autowalk_on / autowalk_off (else fi-br-person-walking-arrow-right)` | `autowalk / autowalk_off` |
| stance | `UI_ZeD_Wheel_GameSpeed` | `vanilla speedControls/Pause_Off` | `ff1` |
| stance | `UI_ZeD_Wheel_Zoom` | `vanilla ZoomIn` | `zoom_in` |
| stance | `UI_ZeD_Wheel_View` | `eye` | `eye` |
| stance | `UI_ZeD_Wheel_Help` | `info-guide` | `help` |
| stance | UI_ZeD_Wheel_Light (or the light's name) | `lightbulb-on` | `bulb_on` |
| stance > Sit | ContextMenu_SitGround / UI_ZeD_Wheel_GetUp | `emotes/sit_on / sit_off` | `sit_ground / sit_ground_off` |
| stance > Sit | UI_ZeD_Wheel_SitOn / UI_ZeD_Wheel_SitOnSeat | `chair` | `sit_seat` |
| stance > Speed | IGUI_BackButton_Play / UI_optionscreen_binding_Pause | `speedControls/Play_Off / Pause_Off` | `play / pause` |
| stance > Speed | IGUI_BackButton_FF1 / FF2 / FF3 | `speedControls/FFwd1_Off / FFwd2_Off / Wait_Off` | `ff1 / ff2 / wait` |
| stance > Zoom | IGUI_BackButton_Zoom (nearer / farther) | `ZoomIn / ZoomOut` | `zoom_in / zoom_out` |
| stance > View | UI_ZeD_Wheel_HideInterface / UI_ZeD_Wheel_ShowInterface | `eye` | `eye_off / eye` |
| stance > View | `UI_ZeD_Wheel_ResetWindows` | `rotate-left` | `rotate` |
| stance > View | `UI_ZeD_Settings_TextSize` | `text-box-dots` | `textsize` |
| stance > View | `UI_mainscreen_option` | `gears` | `gears` |
| stance > Help | `UI_optionscreen_binding_Toggle Survival Guide` | `info-guide` | `guide` |
| stance > Help | `UI_ZeD_Wheel_ControllerMap` | `question` | `gamepad` |
| ZeD setup | `UI_ZeD_Settings_BaseTheme` | `settings` | `theme` |
| ZeD setup | `UI_ZeD_Settings_TextSize` | `text-box-dots` | `textsize` |
| ZeD setup | `UI_ZeD_Settings_SeeThrough` | `architectural-windows-017-window-16` | `seethrough` |
| ZeD setup | `UI_ZeD_Settings_FocusStyle` | `fi-br-hand-back-point-right` | `focus` |
| ZeD setup | `UI_ZeD_Settings_UiScale` | `magnifying-glass-eye` | `scale` |
| ZeD setup | `UI_ZeD_Settings_Moodles` | `smile` | `smiley` |
| ZeD setup | `UI_ZeD_Settings_ActionBar` | `clock` | `progress` |
| ZeD setup | `UI_ZeD_Msg_Title` | `inbox-in` | `inbox` |
| ZeD setup | `UI_ZeD_Wheel_ResetWindows` | `rotate-left` | `rotate` |
| ZeD setup | `UI_ZeD_Options_GroupZed` | `gears` | `gears` |
| ZeD setup | `UI_ZeD_Settings_SafeMode` | `bolt-slash` | `safemode` |

Each picker in the ZeD setup wheel gives its choices the setting's icon: the theme's choices `theme`, the text sizes `textsize`, and so on.

The tab slices (`C.tabs`, `Wd.tabs`, and the Health, Equipment and Radio slices) name a tab by its icon name:

| Tab icon | New id |
|---|---|
| `loot-tab-white` | `crate` |
| `equipment-tab-white` | `jacket` |
| `health-tab-white` | `heart` |
| `thermal-tab-white` | `thermometer` |
| `identy-tab-white` | `idcard` |
| `journal-tab-white` | `notebook` |
| `skills-tab-white` | `skills` |
| `radio-tab-white` | `walkie` |
| `craft-tab-white` | `craft` |
| `build-tab-white` | `bricks` |
| `move-tab-white` | `chair` |
| `map-tab-white` | `map` |
| `forage-tab-white` | `magnifier` |
| `farm-tab-white` | `cow` |
| `vehicle-tab-white` | `car` |
| `appearance-tab-white` | `mirror` |
| `traits-tab-white` | `traits` |

### 3b. Vanilla's wheels (`ZeD_Wheel.W.picture`)
Try them in this order, as today: the words, then the pictures that stay, then the pictures by name.

**The words** (`TEXT_ICONS`). Several vanilla slices share one picture, and their words tell them apart.

- **Matching:** find the key's translation in the slice's text, as `TEXT_ICONS` does now. For a one-word key such as `IGUI_Emote_Group`, match the slice's whole text, not a piece of it.
- **Keys with arguments:** `IGUI_BackButton_Zoom`, `ContextMenu_Vehicle_AttachTrailer`, `ContextMenu_Vehicle_AttachVehicle` and `ContextMenu_Vehicle_DetachTrailer` take arguments, so match the words before the first `%`.
- **Rows that name a picture** hold only with that picture.

| Key | With picture | New id | Why |
|---|---|---|---|
| `UI_optionscreen_binding_Toggle Survival Guide` |  | `guide` | vanilla shows the shrug |
| `IGUI_MiniMap_Toggle` |  | `minimap` | all three map slices share Map_On |
| `IGUI_MiniMap_Focus` |  | `pin` | all three map slices share Map_On |
| `IGUI_Emote_Shout` |  | `bullhorn` | vanilla shows the Talkative trait |
| `IGUI_Emote_Group` |  | `group` | the emote category; vanilla reuses Follow me's picture |
| `IGUI_BackButton_Zoom` | `ZoomIn` | `zoom_in` | ZoomIn and ZoomOut also mean add and remove elsewhere |
| `IGUI_BackButton_Zoom` | `ZoomOut` | `zoom_out` |  |
| `ContextMenu_Vehicle_AttachTrailer` |  | `link` | vanilla shows ZoomIn |
| `ContextMenu_Vehicle_AttachVehicle` |  | `link` | towing another vehicle |
| `ContextMenu_Vehicle_DetachTrailer` |  | `unlink` | vanilla shows ZoomOut |
| `ContextMenu_VehicleHeadlightsOn` |  | `headlight_on` | vehicle_lightsON is the light sources' too |
| `ContextMenu_VehicleHeadlightsOff` |  | `headlight_off` |  |
| `ContextMenu_VehicleHotwire` |  | `hotwire` | vanilla shows the ignition |
| `ContextMenu_VehicleHotwireSkill` |  | `hotwire_off` | not skilled enough yet |
| `IGUI_EnterVehicle` |  | `car_enter` | vanilla shows Change seats |
| `IGUI_ExitVehicle` |  | `car_exit` |  |
| `ContextMenu_Open_door` |  | `car_door` | vanilla shows Exit |
| `ContextMenu_Close_door` |  | `car_door` |  |
| `IGUI_OpenHood` |  | `car_door` |  |
| `IGUI_CloseHood` |  | `car_door` |  |
| `IGUI_OpenTrunk` |  | `car_door` |  |
| `IGUI_CloseTrunk` |  | `car_door` |  |
| `ContextMenu_Unlock_Doors` |  | `padlock_open` | Lock and Unlock share vehicle_lockdoors |
| `ContextMenu_UnlockDoor` |  | `padlock_open` |  |
| `IGUI_UnlockHood` |  | `padlock_open` |  |
| `IGUI_UnlockTrunk` |  | `padlock_open` |  |
| `ContextMenu_Vehicle_Wash` |  | `wash` | vanilla shows the water drop item |
| `ContextMenu_CheckAnimalInsideTrailer` |  | `cow` | vanilla shows the lamb item |
| `ContextMenu_FullInventory` |  | `gas_can` | fuel, greyed: vanilla shows the petrol item |
| `ContextMenu_VehicleNeedHose` |  | `gas_siphon` | siphoning, greyed: needs a hose |

**The pictures that stay** (`KEEP`): `item_`, `trait_`, `xbox`, `joypad`, `media/inventory`.

**The pictures by name** (`TEX_ICONS`, matched on a piece of the texture's lower-case name).

- **Order:** the first match wins, so keep this order. For example, `emotes/wavehello` must come before `emotes/wave`.
- **Emote categories:** they come in with their first emote's picture. Friendly is `thumbsup`, Hostile `thumbsdown`, Signal `moveout`. Group is `followme`, which the words above turn into `group`.

*Vehicle*

| Picture | New id |
|---|---|
| `vehicle_changeseats` | `seat` |
| `vehicle_ignitionon` | `key` |
| `vehicle_ignitionoff` | `key_off` |
| `vehicle_lightson` | `bulb_on` |
| `vehicle_lightsoff` | `bulb_off` |
| `vehicle_temperaturehot` | `heat` |
| `vehicle_temperaturecold` | `snowflake` |
| `vehicle_horn` | `horn` |
| `vehicle_lightbar` | `lightbar` |
| `vehicle_speakers` | `speaker` |
| `vehicle_windowopen` | `window_open` |
| `vehicle_windowclosed` | `window_close` |
| `vehicle_smash_window` | `window_smash` |
| `vehicle_lockdoors` | `padlock` |
| `vehicle_repair` | `engine` |
| `vehicle_sleep` | `bed` |
| `vehicle_exit` | `car_exit` |
| `vehicle_refuel_from_pump` | `gas_pump` |
| `vehicle_add_gas` | `gas_can` |
| `gas_refuel` | `gas_can` |
| `vehicle_siphon_gas` | `gas_siphon` |
| `gas_siphon` | `gas_siphon` |

*Firearm and light*

| Picture | New id |
|---|---|
| `firearmradial_insertmagazine` | `mag_in` |
| `firearmradial_ejectmagazine` | `mag_out` |
| `firearmradial_bulletsintomagazine` | `rounds_mag` |
| `firearmradial_bulletsintofirearm` | `rounds_in` |
| `firearmradial_bulletsfromfirearm` | `rounds_out` |
| `firearmradial_unjam` | `unjam` |
| `firearmradial_rack` | `rack` |
| `firearmradial_chamberround` | `chamber` |
| `lightsourceradial_insertbattery` | `battery_in` |
| `lightsourceradial_removebattery` | `battery_out` |

*Animal*

| Picture | New id |
|---|---|
| `animalactions_kill` | `knife` |
| `animalactions_grab` | `carry_animal` |
| `animalactions_milk` | `milk` |
| `animalactions_pet` | `pet` |
| `animalactions_rope` | `rope` |
| `animalactions_shear` | `scissors` |
| `animalactions_stats` | `info` |

*Back button, furniture, map*

| Picture | New id |
|---|---|
| `heart2_on` | `heart` |
| `carpentry_on` | `craft` |
| `build_tool` | `bricks` |
| `furniture_off2` | `chair` |
| `furniture_pickup` | `box_up` |
| `furniture_place` | `box_down` |
| `furniture_rotate` | `rotate` |
| `furniture_disassemble` | `screwdriver` |
| `furniture_on2` | `wrench` |
| `foraging/eyeconon` | `eye` |
| `foraging/eyeconoff` | `eye_off` |
| `search_on_64` | `magnifier` |
| `search_off_64` | `magnifier_off` |
| `animalzone_on_64` | `fence` |
| `buildingroomseditor_64` | `rooms` |
| `worldmap/map_on` | `map` |
| `speedcontrols/play_off` | `play` |
| `speedcontrols/pause_off` | `pause` |
| `speedcontrols/ffwd1_off` | `ff1` |
| `speedcontrols/ffwd2_off` | `ff2` |
| `speedcontrols/wait_off` | `wait` |
| `zoomin` | `plus` |
| `zoomout` | `minus` |

*Emotes and stances*

| Picture | New id |
|---|---|
| `emotes/wavehello` | `wave` |
| `emotes/wavebye` | `wave_bye` |
| `emotes/wave` | `wave` |
| `emotes/clap` | `clap` |
| `emotes/thumbsup` | `thumbs_up` |
| `emotes/thumbup` | `thumbs_up` |
| `emotes/thumbsdown` | `thumbs_down` |
| `emotes/thumbdown` | `thumbs_down` |
| `emotes/thankyou` | `bow` |
| `emotes/insult` | `insult` |
| `emotes/stop` | `hand` |
| `emotes/surrender` | `surrender` |
| `emotes/followme` | `follow_me` |
| `emotes/comehere` | `come_here` |
| `emotes/comefromfront` | `come_here` |
| `emotes/yes` | `yes` |
| `emotes/no` | `no` |
| `emotes/shrug` | `shrug` |
| `emotes/undecided` | `undecided` |
| `emotes/ceasefire` | `target_off` |
| `emotes/fire` | `target` |
| `emotes/moveout` | `move_out` |
| `emotes/freeze` | `freeze` |
| `emotes/followbehind` | `follow_behind` |
| `emotes/salute` | `salute` |
| `emotes/group` | `group` |
| `emotes/gears` | `gears` |
| `emotes/crouch_on` | `sneak` |
| `emotes/crouch_off` | `sneak_off` |
| `emotes/sit_on` | `sit_ground` |
| `emotes/sit_off` | `sit_ground_off` |
| `emotes/autowalk_on` | `autowalk` |
| `emotes/autowalk_off` | `autowalk_off` |

### 3c. Drawn, not placed yet
`back`, `carry`, `climb`, `point`, `run`, `stand`, `walk` aren't on a wheel yet. They're for the context strip.

## 4. Checks
- **Every wheel at 1x and 2x:** crisp (no smoothing), centred, and the right drawing for the box.
- **The vehicle radial:** these pairs share a picture and must still come out different:
  - headlights against a light source's on and off;
  - get in against change seats;
  - get out against a door;
  - lock against unlock;
  - hitch against unhitch;
  - zoom against plus and minus.
- **The emote wheel:** the categories (Friendly a thumb up, Hostile a thumb down, Group two people, Signal move out, Shout the bullhorn), and the emotes under each.
- **A slice that's off** still greys.
- **QA's wheel shots** (`zedqa_wheels.lua`) retaken.

## 5. Not in this handoff
- **The context strip's icons:** the same style, in later batches.
- **The window tabs** keep their own art. The tab icons here are only for wheel slices that open a tab.
