# Compatibility round 2: which Workshop mods deserve a ZeD tab or surface

Survey date: Oct 25 2026. Read-only: no game launch, no edit to any mod or to ZeD.

"Hidden under ZeD today" is judged from the Lua (ZeD's hooks in `HOOK_MAP.md` and the ZeD files named below), not from playing the game. Where a call rests on an inference and not on a line of code, the section says so.

## How to read the paths

- Mod files are written `<workshop id>/<mod folder>/<version folder>/media/lua/...:line`, under `E:\Project Zomboid\SteamApps\workshop\content\108600\`. The version folder is the newest one up to 42.21 (what the game loads beside `common`).
- `ZeD:` means `C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\lua\client\ZeD\`.
- `V:` means the game's own Lua, `E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\lua\client\`.
- Effort: S = a few hours, M = a day, L = several days.
- Subscribers are the lifetime count from the inventory (`steam.subs`).

## Coverage

- Pool: 918 Workshop items in the inventory; 259 are Build 42 items with 100,000+ subscribers whose Lua matches at least one of the window / character / inventory / HUD / radio / map / crafting signals.
- A second scan looked for code that hooks the specific screens ZeD replaces (a tab on the Character window, the Health panel, the skill bars, the inventory page, the left-edge column, the hotbar, the map, the radio window, the mechanics window, the dashboard, the moodles): 127 items at 100,000+ subscribers hit. I read the code of the mods named in this report (about 70 including the set-aside list) and set the rest aside on their file list, their mod.info description or both: pure content, vehicle and weapon packs, NPC mods, libraries, and mods whose hooks turned out to be a few lines of behaviour.
- Not read past the file list: True Music Radio, New Music, NeatUI Hairstyler (read to the method names only), Neat Rocco's UI, Equipment UI Standalone, NeatUI Equipment, Better Containers, Project A-Life, DebugMenu, Playable minigames, Seed Season Indicator and the 40-odd smaller hits in the scan's tail. If the director wants one of those checked, it is a short job.
- Nothing was run. Every "hidden" call below is reading, as stated at the top.

## What the survey found, in short

- Almost nothing here needs a brand-new tab. The pattern that fits is a section or a small piece inside a ZeD tab that already exists (Skills, Health, Journal, Identity, Equipment, Maps, Craft, Loot, Vehicle, the belt, the dash). Only four mods look like they could deserve a screen of their own: Traits As Skills (a Traits tab beside Skills), Armor Makes Sense (a Burden section, or a tab), Antibodies (Knox infection details, in Health) and Lifestyle: Hobbies (Ambitions, optional). Traits As Skills and Armor Makes Sense have a clean data layer that does not need the mod's panels; Antibodies' own window opens by itself, so a button reaches it today.
- The Maps tab is the biggest cluster. ZeD's map is its own class (`ZeD_WorldMap`, `ZeD:MapsTab.lua:270`), not the game's `ISWorldMap`, so six map mods lose their screens at once (Map Legend UI, Draw On The Map, Map Symbol Size Slider, Share Annotations, Players On Map, Where Am I?). One overlay hook in `ZeD_WorldMap:render` (`ZeD:MapsTab.lua:962`) would carry most of them.
- ZeD has no way to cut or tie hair or trim a beard in game. The game keeps those on the Character screen's Hair and Beard buttons, which ZeD never shows. Three popular hair mods build on that menu, so one native Identity-tab piece brings all three.
- The biggest audiences are on two small, native pieces: ammo on the belt and dash lamp colours (Common Sense, 5.0M) and the read marks in item lists (Has Been Read, 4.1M).
- A mod whose screen does not just hide but pops up the game's own window on top of ZeD: Mini Health Panel (2.45M). Its click calls `getPlayerInfoPanel(n):toggleView(...)`, and ZeD never touches that window (see "Surprises").
- One mod where ZeD shows a wrong picture rather than a missing one: Beyond Ten (123k) lets skills run to level 15, and ZeD's Skills tab draws level 10 as full (`ZeD:SkillsTab.lua:146,191,847`). Medical Meister (282k, click a moodle to act) only fails with the Bottom moodle setting.
- Mods that replace whole screens ZeD also replaces (inventory, crafting, building, character screen, dashboard, seat chooser) are listed as "use one". Several of those are not yet in `2_compatibility_b_notes.txt`: Inventory Tetris, Equipment UI Standalone, NeatUI Equipment, Neat Rocco's UI, Better Containers, Knox Buildworks, TwisTonFire Better Character Info, Vehicle Seat UI (KI5), This Is Your Life.

## ZeD facts the recommendations lean on

- Character window: `ZeD_CharacterWindow.addTab(def)` exists (`ZeD:ZeD_CharacterWindow.lua:590`; SPNCC is its only user, `ZeD:ModSupport/SPNCC.lua`).
- World window: there is no add-tab call. `WORLD_TABS` is a local table (`ZeD:ZeD_WorldWindow.lua:82`), exported read-only as `ZeD_WorldWindow.TABS`. A World tab for a mod would need that small call first (S), and no candidate below actually needs a new World tab; they are sections inside Maps, Craft, Loot and Vehicle.
- No tab has a hook for "a section another mod adds". Every "section inside tab X" below assumes one small shared hook per tab (a list of section drawers that ModSupport files push into). Build it once, reuse it for all of them (S).
- Maps tab: the map is `ZeD_WorldMap`; its per-frame overlay chain is `ZeD:MapsTab.lua:962` (stash maps, flyer markers, annotations, tool cursor, gamepad cursor). Its toolbar is `renderMapToolbar` (`:1033`) and marks go in through `_placeAnnotationAt` (`:548`). The game's `ISWorldMap.ShowWorldMap` and friends are routed to the Maps pop-out (`ZeD:Overrides/WorldMap.lua`).
- Loot: the World window builds its own container list (`ZeD:ZeD_WorldWindow.lua:2341` buildWorldContainers). ZeD never fires the game's `OnRefreshInventoryWindowContainers` event (grep: 0 hits in ZeD).
- Health: the tab calls `ISHealthPanel.doBodyPartContextMenu(adapter, bp, x, y)` through a thin stand-in (`ZeD:HealthTab.lua:418-431`), so mods that wrap that function still add their menu entries. The stand-in has `character`, `otherPlayer`, `blockingMessage`, `actions`, `getDoctor`, `getAbsoluteX/Y`, `checkItems` and `checkContainerItems` (`:419-430`); a mod that calls anything else on `self` in that function (for example `getPatient`) would raise an error there. None of the mods read here does so in the menu path, but it is the thing to watch.
- Vehicle: verbs are the game's own list (`ZeD:MechanicsTab.lua:400-411`); X or right-click on a part runs the game's `doPartContextMenu` on the game's mechanics window object (`:721-727`), so mods that wrap it still show in that menu.
- The game's Character Info window (`data.characterInfo`, `getPlayerInfoPanel`) is never referenced by ZeD (grep over all of `42/media/lua`: 0 hits). It is created and never shown, but anything that calls `:toggleView(...)` on it will show it.
- The left-edge column (`ISEquippedItem`): its window buttons are hidden (`ZeD:Overrides/ScreenIcons.lua:29`), its hand slots hidden (`ZeD:Overrides/Belt.lua:199-200`), and in single player without `-debug` the whole column goes unless another mod has a visible child on it at frame 30 (`ZeD:Overrides/Belt.lua:75-102`).
- Hair: no `onCutHair`, `hairMenu` or `beardMenu` anywhere in ZeD. `ZeD:ZeD_ActionBar.lua:120` only names the actions.
- Craft/Build lists show no XP reward and no "from which mod" line (grep for `getXPAward`, `getModID`, `getModName` in `CraftingCore.lua`, `CraftingTab.lua`, `BuildingTab.lua`: 0 hits).
- The belt's hand squares show no ammo (grep for ammo in `ZeD:ZeD_Belt.lua`: 0 hits). The dashboard has an engine warning lamp only (`ZeD:ZeD_Dashboard.lua:181-182`); it has no battery/engine/heater condition text and no seatbelt or high-beam lamp.

## Ranked shortlist

Best first. "Hidden" is yes/no with where.

| # | Mod | Subs | What it shows | Hidden under ZeD today | Recommendation | Effort | Why |
|---|---|---|---|---|---|---|---|
| 1 | [Common Sense](https://steamcommunity.com/sharedfiles/filedetails/?id=2875848298) | 5,045,167 | The ammo type picture and count beside the main-hand slot; dash battery, engine and heater lamps tinted by charge and condition | Yes: both are drawn on the game's left-edge column and dashboard, which ZeD hides or replaces | A card or HUD piece: ammo readout on the belt's main-hand square, lamp tint on ZeD's dash | S | Vanilla gun and vehicle calls only, no mod data; largest audience of the whole list; the belt shows no ammo at all today |
| 2 | [Has Been Read](https://steamcommunity.com/sharedfiles/filedetails/?id=2544353492) | 4,145,853 | Little marks on books, magazines, flyers, maps, CDs and tapes: not read, part read, already read, your own ticked / unticked mark, "good for your next skill level" | Yes: drawn on the game's inventory list rows | A card or HUD piece: a badge on ZeD list rows | S | One call returns the marks (`P4HasBeenRead.setTextures`); its mark menu already works through the item context menu |
| 3 | [Skill Recovery Journal](https://steamcommunity.com/sharedfiles/filedetails/?id=2503622437) | 4,055,428 | A colour strip under each skill bar (settled, deducted, recorded, not yet written) plus lines in the skill tooltip | Yes: on the game's skill bars, inside the game's Character window | A section inside the Skills tab | S | Four plain functions give the numbers; the journal item and its menu already work |
| 4 | Hair and beard menus: [Spongie's Hairstyle Unlocker](https://steamcommunity.com/sharedfiles/filedetails/?id=3041733782), [Improved Hair Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=3589548354), [NeatUI Hairstyler](https://steamcommunity.com/sharedfiles/filedetails/?id=3760534563) | 741,976 / 372,182 / 170,273 | Cut, tie and untie hair and trim beards in game; the mods add more styles, gel and a picture menu | Yes: the Hair and Beard buttons sit on the game's Character screen; ZeD has no equivalent at all | A section inside the Identity tab (Hair, Beard) that calls the game's `ISCharacterScreen:hairMenu / beardMenu` | S to M | Fixes a hole in ZeD itself and brings three mods in one move, the way SPNCC's shave actions were reached |
| 5 | [Map Legend UI](https://steamcommunity.com/sharedfiles/filedetails/?id=2710167561) | 3,180,831 | A button on the map that opens a colour legend (community, retail, industrial, residential, restaurants, hospitality, medical, parks) | Yes: the button is added to the game's full-screen map | A section inside the Maps tab (a Legend chip) | S | Static pictures and words, no state; ZeD's map has no legend at all, not even the game's own key |
| 6 | [Proximity Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=2847184718) | 3,043,569 | One extra "everything nearby" container that lists the items of every container in reach | Yes: it is built inside the game's loot window refresh; ZeD builds its own container list and never fires that event | A section inside the World window Loot tab (a Nearby column) | M | Simple idea (union of nearby containers, locked ones left out); best done natively so it works without the mod |
| 7 | [KillCount](https://steamcommunity.com/sharedfiles/filedetails/?id=2553809727) | 2,950,962 | A Kills tab: kills by weapon group and weapon, and in multiplayer a picker for other players' and dead players' totals | Yes: it is a tab in the game's Character window | A section inside the Journal tab | S to M | ZeD counts its own kills; what is missing is the history from before ZeD and the multiplayer tables, which are plain mod data |
| 8 | [Mini Health Panel](https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937) | 2,453,999 | An always-on little body figure at the bottom left showing wounds; click opens the health view | Partly: the widget is its own HUD piece and shows; the click opens the game's Character window on top of ZeD | Leave as its own window, and route the click to ZeD's Health tab | S | Fix on ZeD's side: catch `toggleView` on the game's Character window; the same guard covers any other mod that calls that window directly |
| 9 | [Map Symbol Size Slider](https://steamcommunity.com/sharedfiles/filedetails/?id=2734705913) | 2,232,588 | A slider that scales every map mark and note | Yes: it sits inside the game's map-symbols panel | A section inside the Maps tab (a size slider on the toolbar) | S | ZeD's mark preview already reads the same global scale; only the control is missing |
| 10 | [Draw On The Map](https://steamcommunity.com/sharedfiles/filedetails/?id=2804531012) | 2,392,013 | A pencil button and panel: freehand draw, straight line, erase, size and fill sliders | Yes: added to the game's map and map-item panels | A section inside the Maps tab (a Draw tool on the toolbar) | M to L | Marks go in through one map call (`addTexture`), but the mod's tool classes expect the game's symbols panel, so ZeD would write its own tool |
| 11 | [Reorder Containers](https://steamcommunity.com/sharedfiles/filedetails/?id=2901962885) (and [Better Containers](https://steamcommunity.com/sharedfiles/filedetails/?id=3586216562), 230,673) | 2,295,696 | Drag container buttons into your own order, with lock buttons | Yes: it works on the game's container button column | A section inside the Loot tab (container strip order) | M | A native feature in ZeD's own strip is cleaner than reading the mod's saved order; the discontinued mod is the reference |
| 12 | [Smarter Storage](https://steamcommunity.com/sharedfiles/filedetails/?id=3290232938) | 1,242,067 | Your own name, picture and colour for a container, presets, capacity text | Yes: drawn on the game's container buttons | A section inside the Loot tab (read first, edit card second) | S to M | Everything lives in three keys on the container's object data, so reading it is S; the editor is the M part |
| 13 | [Condition On Dash](https://steamcommunity.com/sharedfiles/filedetails/?id=3306168142) | 910,315 | Hover text on the dash lamps: engine condition, battery condition and charge, each headlight's condition | Yes: on the game's dashboard | A card or HUD piece: hover text on ZeD's dash lamps | S | Plain vehicle calls, no mod data; ZeD's dash shows a warning lamp only |
| 14 | [Moodle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3396446795) | 835,536 | Extra moodles (other mods' needs) drawn beside the game's column | No, but stranded: fixed at the right edge from y=120 down, whatever ZeD's Moodles option says | A card or HUD piece: ZeD's moodle placement adopts the framework's moodles | S to M | Same family: Companion Dogs and Lifestyle draw their own stacks; one rule for "extra moodles" covers all |
| 15 | [Auto Mechanics](https://steamcommunity.com/sharedfiles/filedetails/?id=3387539308) | 727,921 | "Train mechanics", "Uninstall all", "Continue", "Inflate all tires" in the vehicle mechanics menu | Partly: reachable through ZeD's X or right-click part menu; the vehicle-wide ones sit in a part menu | A section inside the Vehicle tab (header buttons) | S | Four mod calls give the availability and the jobs; the buttons run the mod's own actions |
| 16 | [Players On Map](https://steamcommunity.com/sharedfiles/filedetails/?id=2879960936) | 802,773 | A dot and name for each other player on the map and mini-map (multiplayer, plus split screen) | Yes: drawn by hooking the game's map render | A section inside the Maps tab (overlay dots) | S | The mod's data (`pom_getPlayers`, sandbox rules) is global; ZeD draws the dot in its own overlay chain |
| 17 | [Share Annotations](https://steamcommunity.com/sharedfiles/filedetails/?id=2815560151) | 713,637 | Tick boxes to show or hide each learned set of map notes, an x to delete one | Yes: a panel added to the game's map; the show/hide state the mod saves is applied only when the game's map opens | A section inside the Maps tab ("Learned notes") | S | Three clean calls on a global (`BLTAnnotations`); hidden sets stay hidden with no way to turn them back on under ZeD |
| 18 | [Where Am I?](https://steamcommunity.com/sharedfiles/filedetails/?id=3097650043) | 690,330 | A header on the map naming the area the player is in | Yes: added to the game's map; its area check runs only when the game's map opens | A section inside the Maps tab (a line under the title) | S | One global string (`BB_WhereAmI.currentArea`) and one refresh call |
| 19 | [Antibodies](https://steamcommunity.com/sharedfiles/filedetails/?id=2392676812) | 677,369 | A Knox infection window (condition, wound, infection and hygiene effects with progress) and a Hygiene tab (dirt and blood per body part) | Yes: the button is added to the game's Health panel, the tab to the game's Character window | A section inside the Health tab (Knox infection button first, then the hygiene part list) | M | The window opens on its own (`AntibodiesWindow.show`), so a button is S; the hygiene list is plain per-part numbers |
| 20 | [TV & Radio ReInvented](https://steamcommunity.com/sharedfiles/filedetails/?id=3420581050) | 540,843 | Real video on the TV screen by channel and hour, a VHS slot, merged radio, ham, CD and car-radio panels | Yes: it replaces the game's radio window file; ZeD's Radio tab and car radio do not use it | A section inside the World window Radio tab (a TV screen face) | S to M | The video textures and the channel-to-clip choice are reusable; the rest of its panels are duplicates of ZeD's radio faces |
| 21 | [Neat Crafting - XP & Mod Display](https://steamcommunity.com/sharedfiles/filedetails/?id=3540503606) | 464,500 | XP each recipe awards and a "from which mod" line, plus two filters (XP only, mod only) | Yes: it is an add-on to Neat Crafting, which ZeD replaces | A section inside the Craft tab (XP and source on the recipe, two filters) | S | Plain recipe calls (`getXPAward`, `getModID`); ZeD has neither today. A native feature, no mod needed |
| 22 | [The Only Cure](https://steamcommunity.com/sharedfiles/filedetails/?id=3580276809) | 400,871 | Amputated limbs drawn on the health body figure, tinted by healing; prosthesis; saw dropped on a limb | Partly: the cut and clean menu entries ride on `doBodyPartContextMenu` and should show; the drawing and the drag-the-saw route do not | A section inside the Health tab (marks on ZeD's body figure) | M | Two plain lookups (`GetHighestAmputatedLimbs`, cicatrization time); the figure is ZeD's own drawing |
| 23 | [Working Seatbelt](https://steamcommunity.com/sharedfiles/filedetails/?id=3055029361) | 312,061 | A seatbelt lamp on the dash (red when the engine runs and the driver is not belted) and a chime toggle | Yes: added to the game's dashboard; the key still works | A card or HUD piece: a lamp on ZeD's dash with a right-click for the chime | S to M | Three mod calls (`isWearingSeatbelt`, chime state, `onDoSeatbelt`); one more lamp on ZeD's dash plates |
| 24 | [More Description For Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3623919908) | 216,426 | Trait and occupation tooltips extended with the real effects, free recipes and foraging numbers | Yes: ZeD's Identity tab and Traits screen read the plain trait description | A section inside the Identity tab (trait hover) and the Traits screen | S | A pure function, `MDFT.addDescriptionToTooltip(definition, text)`, returns the longer text |
| 25 | [Detailed Skill Tooltips](https://steamcommunity.com/sharedfiles/filedetails/?id=3572846242) | 189,932 | What each skill level unlocks, in the skill bar tooltip and the character-creation XP-boost list | Yes: on the game's skill bars; ZeD's Skills tab has no level hover | A section inside the Skills tab (a level hover) | S | A pure text function, `DST.SkillTooltips.appendLevelTooltip`; needs a hover on ZeD's skill pips first |
| 26 | [Armor Makes Sense](https://steamcommunity.com/sharedfiles/filedetails/?id=3677430162) | 174,701 | A Burden tab: load, endurance, heat, breathing, melee and sleep costs of worn gear, a body map, the heaviest items, Take off / Drop / Wear armor buttons | Yes: its tab is injected into the game's Character window | A section inside the Equipment tab (Burden), a tab only if the director wants it | M | The mod ships a screen-free view model (`BurdenView.build`); only the snapshot gathering needs copying |
| 27 | [Traits Purchase System](https://steamcommunity.com/sharedfiles/filedetails/?id=3211693903) | 175,437 | Spend trait points to buy a good trait or remove a bad one | Yes, and unreachable: its only door is a hover pop-up on the game's Health button, which ZeD hides | A section inside the Identity tab (points, buy, remove) | S for a button, M for a native list | The window object is global (`TraitsPurchaseSystem_mod.Windows[chr]:toggleWindow()`), so a button is a few lines |
| 28 | [Traits As Skills](https://steamcommunity.com/sharedfiles/filedetails/?id=3784847437) | 153,861 | A Traits tab beside Skills: evolving traits drawn like skills, with levels and stages; an open platform other mods register into | Yes: it is a tab in the game's Character window | A Character window tab (Traits, after Skills) | M | Clean registry and state calls; same bars as the Skills tab; other mods add their own traits to it |
| 29 | [Full Dynamic Scarring System](https://steamcommunity.com/sharedfiles/filedetails/?id=3750907049) | 129,901 | An Injury History list (date, injury, body part, cause) | Yes: a tab in the game's Character window | A section inside the Journal tab (Injury history) | S | Pure player data (`ScarSystem.history`), no mod functions needed |
| 30 | [True Music B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3397198968) (related, only skimmed: [True Music Radio](https://steamcommunity.com/sharedfiles/filedetails/?id=3100475013), [New Music](https://steamcommunity.com/sharedfiles/filedetails/?id=3739256725)) | 318,666 | A boombox / walkman window with a cassette slot, autoplay, speaker link | No for the window (the mod's own, opened from the item menu); the Radio tab would show a boombox without its cassette slot | A section inside the World window Radio tab (music slot) | M | Device state lives in the radio item's `tcmusic` table; worth doing only if the director sees players hitting the plain face |
| 31 | [Lifestyle: Hobbies](https://steamcommunity.com/sharedfiles/filedetails/?id=3403870858) | 769,404 | Ambitions (goals with progress), a beauty score icon, mirror, DJ booth, playlists, research and production windows | Mostly no: windows open from world objects or the emote wheel; the beauty icon is a free HUD piece | Leave as its own window; optionally an Ambitions section in the Journal tab | M (optional) | 500 Lua files; almost all of it works; only Ambitions reads like journal content |
| 32 | [Modern Status](https://steamcommunity.com/sharedfiles/filedetails/?id=3451167732) (and [Simple Status](https://steamcommunity.com/sharedfiles/filedetails/?id=2867431511), 1,210,970) | 897,099 | Draggable status bars or circles for 30-odd needs | No for the bars (free HUD pieces); Yes for the settings menu, opened by right-clicking the game's Health button | Leave as its own window; give its settings a door | S | The bars work; its layout menu is unreachable, so a Settings row that calls it is enough |
| 33 | [Beyond Ten - Level 15 Skills](https://steamcommunity.com/sharedfiles/filedetails/?id=3765241705) | 123,224 | Skills go past level 10 to 15 on mastery XP: 15 pips per skill, progress toward the next mastery rank, tooltips | Yes, and it reads wrong: ZeD's Skills tab treats level 10 as full, so a player past 10 sees a full bar and no progress | A section inside the Skills tab (five extra pips and mastery progress) | S to M | Four plain calls (`GetEffectiveLevel`, `GetLevelProgress`, `GetMasteryCost`, `MAX_LEVEL`); added after the ranking was set, by value it belongs near row 26 |
| 34 | [Medical Meister](https://steamcommunity.com/sharedfiles/filedetails/?id=3173649443) | 281,573 | Click a moodle and the matching action runs (eat, drink, take painkillers, bandage and so on) | Mostly no: it finds the click from the game's moodle column position; with the Right and Left moodle settings the column is still the real one. With the Bottom setting the real column is parked off screen and ZeD's copy row gets no action | A card or HUD piece: in the Bottom row, a click on a moodle calls the mod's `doAction` | S | One global call (`P4MedicalMeister.doAction(moodleType)`); matters only for the Bottom setting |

## Groundwork that several rows share (build once)

1. A section hook per existing tab (Skills, Health, Journal, Identity, Equipment, Craft, Loot, Maps, Vehicle): `ZeD.ModSupport.addSection(tabId, def)`, drawn after the tab's own content and given a controller stop. Every row above whose recommendation says "a section inside" a tab depends on it (rows 3 to 7, 9 to 12, 15 to 22, 24 to 29 and 33). (S, once)
2. A Maps overlay and toolbar hook, so map mods add a layer or a tool without touching `ZeD_WorldMap:render`. Rows 5, 9, 10, 16, 17, 18. (S, once)
3. Catching the game's Character window when a mod calls `toggleView` on it and opening ZeD's matching tab instead. Row 8 needs it; Traits Purchase System's pop-up (row 27) and Armor Makes Sense's pad handler (row 26) also call it, though only from places that are hidden under ZeD. (S, once)
4. Native, no-mod pieces the survey kept finding: ammo on the belt (row 1), hair and beard (row 4), Legend (row 5), a Nearby column (row 6), XP and source on recipes (row 21), condition hover on the dash (row 13). Each of these helps players with no mod at all.

## Candidates in detail

### 1. Common Sense (5,045,167) - id BB_CommonSense, workshop 2875848298

- Sees: with a ranged weapon in the main hand, an ammo picture and a count (white, yellow under 50%, red under 25%, dark red when empty) beside the hand slot. On the dashboard the battery, engine and heater lamps change colour with charge and condition. The rest of the mod (prying, collecting, context menu entries) is menu work.
- Opens: always on. The ammo pieces are children added to `ISEquippedItem` in `initialise` (`2875848298/CommonSense/42.0/media/lua/client/BB_CS_GunStats_UI.lua:104`, children made at `:112`, shown or hidden by the weapon in `ISEquippedItem:render` `:81`). The lamps are set in `ISVehicleDashboard:prerender` (`.../Vehicles/ISUI/CS_ISVehicleDashboard.lua:47`, `:57`, `:61`, `:66`). Both switch on sandbox options (`GunStats`, `PartsHighlighter`).
- Hidden: yes. ZeD hides the hand slots (`ZeD:Overrides/Belt.lua:199-200`) and, in single player, the whole column when no foreign child is visible at frame 30 (`:75-102`). Common Sense hides its children when no gun is in hand, so by frame 30 the column normally goes and the ammo goes with it. If a gun is in hand when the game starts, the column stays up for the session showing only the ammo; in multiplayer or with `-debug` the column is never hidden, so the readout floats beside the spot where the hand slot was. The dash lamps are on the game's dashboard, which ZeD parks.
- Data: `gun:getCurrentAmmoCount()`, `isRoundChambered()`, `getMaxAmmo()`, `getAmmoType()` (`BB_CS_GunStats_UI.lua:50-53`); `vehicle:getBatteryCharge()`, `getPartById("Engine"):getCondition()` (`CS_ISVehicleDashboard.lua:57-66`). All vanilla calls. ZeD can do it without the mod.
- Recommendation: a card or HUD piece. Ammo on the belt's main-hand square (and a small "chambered" tick); lamp tint on ZeD's dash. Effort S. Why: biggest audience on the list and the data is vanilla, so no dependence on the mod.

### 2. Has Been Read (4,145,853) - id P4HasBeenRead, workshop 2544353492

- Sees: marks on list rows. Not read, part read, already read; your own mark (ticked or unticked, set from the item menu); and a "next target" mark on a skill book that fits your next level. Covers skill books, recipe magazines, flyers, brochures, titled literature, maps, CDs, retail and home VHS (`2544353492/P4HasBeenRead/42.15/media/lua/client/P4HasBeenRead.lua:435-570`).
- Opens: always on, drawn over the game's inventory list by `ISInventoryPane:renderdetails` (`:574`). Marking and unmarking are item context-menu entries (`:310`), which ZeD's context menu still fires.
- Hidden: yes. ZeD draws its own lists and never calls `renderdetails`. ZeD's item card does show pages read, but the quick scan of a bag is lost.
- Data: `P4HasBeenRead.setTextures(player, item, markedMap, recordedMedia, recordedMediaResult)` (`:435`) returns up to three textures; player data `P4HasBeenRead.getModData(player).markedMap` (`:72`). Options through `PZAPI.ModOptions` (`:44-64`). It already works beside Inventory Tetris through a draw event (`:391-427`), proof the call is independent of the game's list.
- Recommendation: a badge on ZeD's list rows (and item card header), drawn only when the mod is on. Effort S. Why: one call, no panel, huge audience.

### 3. Skill Recovery Journal (4,055,428) - id SkillRecoveryJournal, workshop 2503622437

- Sees: under each recordable skill bar a thin strip in four colours (grey free levels from traits and job, orange deducted, green recorded by reading, red not yet written), and tooltip lines: starting level, total XP, deducted, gained, not yet transcribed. An admin panel exists for administrators.
- Opens: the journal item and its Transcribe / Read entries are item-menu entries (`2503622437/Skill Recovery Journal/42.20.1/media/lua/client/Skill Recovery Journal Context.lua`), so they work. The strip is `ISSkillProgressBar:render` (`...SkillProgressBar.lua:139`) and the lines `ISSkillProgressBar:updateTooltip` (`:54`).
- Hidden: yes. ZeD's Skills tab draws its own bars (`ZeD:SkillsTab.lua:624` render, `:169` gatherData).
- Data: `SRJ = require "Skill Recovery Journal Main"`; `SRJ.modDataHandler.getDeductedXP(char)`, `getFreeLevelsFromTraitsAndProfession(char)` (`.../shared/Skill Recovery Journal ModData.lua:43`), `SRJ.ledger.getReadXPAny(char)` (`.../shared/Skill Recovery Journal Ledger.lua:296`), `SRJ.bSkillValid(perk)` (`.../shared/Skill Recovery Journal Main.lua:61`); the sums are in `SRJ_getProgressAmounts` (`...SkillProgressBar.lua:21`).
- Recommendation: a section inside the Skills tab (a strip under each bar and a short hover). Effort S. Why: four functions, no panel; keeps a very common mod usable.

### 4. Hair and beard: Spongie's Hairstyle Unlocker (741,976), Improved Hair Menu (372,182), NeatUI Hairstyler (170,273)

- Sees: the game's own menu to cut, tie and untie hair and to trim a beard needs scissors or a razor and shows each style the character can reach. Spongie's Hairstyle Unlocker (id SpnHairAPI, workshop 3041733782) replaces `ISCharacterScreen:hairMenu` to unlock styles and allow hair gel (`3041733782/Spongie Hairstyle Unlocker/42.18/media/lua/client/SpongieHairUnlocker/ISCharacterScreen.lua:30`; it steps aside if Improved Hair Menu is on, `:2`). Improved Hair Menu (id improvedhairmenubuild42, workshop 3589548354) replaces `hairMenu` (`3589548354/IHM_FORTY_TWO/42.21/media/lua/client/improvedhairmenu/InGame/CharacterScreen.lua:64`) and `beardMenu` (`:200`) with a picture menu in its own window (`.../InGame/HairMenuWindow.lua:4`). NeatUI Hairstyler (workshop 3760534563) is a copy of Improved Hair Menu in the Neat style and replaces the same two methods (`3760534563/NeatUI_Hairstyler/42.20/media/lua/client/improvedhairmenu/InGame/CharacterScreen.lua:78`).
- Opens: the Hair and Beard buttons on the game's Character screen (`V:XpSystem/ISUI/ISCharacterScreen.lua:334` hairMenu, `:479` beardMenu, `:546` onCutHair, `:537` onTrimBeard).
- Hidden: yes, and for everyone. ZeD never shows that screen and has no hair or beard action of its own (grep `onCutHair|hairMenu|beardMenu`: nothing; `ZeD:IdentityTab.lua:123-148` only reads the style name). With ZeD on, a character cannot be given a haircut or have the beard trimmed from any ZeD surface that I found.
- Data: the three mods all replace the same two methods on the game's `ISCharacterScreen`, and read only `self.char`, `self.playerNum` and a button's position (Improved Hair Menu also calls `self:ihm_open_hair_menu`, `CharacterScreen.lua:280`, so the stand-in must inherit from `ISCharacterScreen`). The same stand-in trick ZeD already uses (`ZeD:HealthTab.lua:418-431`, and SPNCC's shave calls `ZeD:ModSupport/SPNCC.lua:243-248`) works: `setmetatable({ char = player, playerNum = n }, { __index = ISCharacterScreen })`, then `ISCharacterScreen.hairMenu(stand_in, fakeButton)`.
- Recommendation: a section inside the Identity tab, "Hair" and "Beard" buttons that open the game's menu through the stand-in (native, whether or not a hair mod is on). Effort S to M. Why: closes a hole in ZeD and the three mods then arrive free; Improved Hair Menu opens its own window, which works.

### 5. Map Legend UI (3,180,831) - id MapLegendUI, workshop 2710167561

- Sees: a button at the bottom left of the map; it opens a small panel with eight colour squares and names (Community, Retail, Industrial, Residential, Restaurants, Hospitality, Medical, Parks). Hides the game's own map key (`2710167561/MapLegendUI/42/media/lua/client/MapLegendUI.lua:26`).
- Opens: `ISWorldMap:createChildren` adds button and panel (`:34`; classes `mapLegendWindow :75`, `mapLegendButton :225`).
- Hidden: yes. ZeD's map is `ZeD_WorldMap`; no `ISWorldMapKey` or legend appears anywhere in ZeD (grep: 0 hits), so the game's own key is missing too.
- Data: textures `media/ui/MapLegendUI/*.png` and keys `UI_legend*`. No state.
- Recommendation: a section inside the Maps tab, a Legend chip on the toolbar. Effort S. Why: ZeD needs a legend anyway; the mod's swatches or ZeD's own can serve.

### 6. Proximity Inventory (3,043,569) - id ProximityInventory, workshop 2847184718

- Sees: a container button named "Proximity Inventory" at the top of the loot strip whose list is every item in every nearby container; keys to turn it on or off (Numpad 1) and to pin it as the selected container (Numpad 0). Sandbox: zombie bodies only; locked containers are left out (`2847184718/ProximityInventory/common/media/lua/client/ProximityInventory/ProximityInventory.lua:41`).
- Opens: on the game's `OnRefreshInventoryWindowContainers` event (`:324`); `OnButtonsAdded` (`:208`) adds the items of all containers into a synthetic container "proxInv" (`:56`, `:242`).
- Hidden: yes. ZeD builds its own container list (`ZeD:ZeD_WorldWindow.lua:2341`) and never fires that event. The 2_compatibility post already says "not checked"; reading says it does not show.
- Data: nothing but vanilla containers; the whole logic is a union of item lists and `CanBeAdded` (`:41`).
- Recommendation: a Nearby column in the World window Loot tab, built natively (items shown from all containers in reach; moves go through each item's real container). Effort M. Why: the mod's idea is a union, which ZeD can do directly; reading the mod's container is not needed. Watch out: transfers must target the item's real source container.

### 7. KillCount (2,950,962) - id KillCount, workshop 2553809727

- Sees: a Kills tab: kills grouped by weapon category with a drop-down of weapons, fire, vehicle and explosive kills added, a total; in multiplayer (sandbox `shareOnServer`, `keepTrackOfDead`) a picker for other players' and dead players' totals. Also draws "(weapon) + fire = total" next to the game's Zombies Killed line, and (sandbox option `includePostDeathUI`) swaps the kills line on the game's post-death screen for its own total (`2553809727/KillCount/42.20/media/lua/client/RISPostDeathUI.lua:3-38`). ZeD's post-death record asks the game clock for that line directly (`ZeD:Overrides/PostDeath.lua:142`), so the mod's total is not used there.
- Opens: tab in the game's Character window (`2553809727/KillCount/42.20/media/lua/client/ISCharacterInfoWindow_AddTab.lua`); panel `ISCharacterKills:render` (`.../ISCharacterKills.lua:57`).
- Hidden: yes. ZeD's Journal tab counts kills itself (`ZeD:JournalTab.lua:311-347`, data `ZeD:KillTracker.lua`, stored as `ZeD_Kills`), but from the day ZeD is installed, by weapon type, and with no other players.
- Data: `KCShared.getLocalKills(player)` (`.../shared/KillCountShared.lua:29`) gives `WeaponCategory[cat].count` and `.WeaponType[type]`; `KCShared.getModData()` (`:8`) holds other players' rows; fire/vehicle/explosion in `player:getModData().AKCModData` (`ISCharacterKills.lua:159-190`).
- Recommendation: a section inside the Journal tab. When the mod is on, ZeD shows the mod's history and, in multiplayer, the player picker. Rows from other mods (Bandits NPC's "Bandits killed", `3268487204/Bandits/42.21/media/lua/client/ISUI/BanditCharacterScreen.lua:3,17`) can share the same block. Effort S to M. Why: removes a double count and keeps a very common stat honest.

### 8. Mini Health Panel (2,453,999) - id MiniHealthPanel, workshop 2866258937

- Sees: a body figure at the bottom left (x 25, y screen height minus its height minus 25), limbs coloured by wound type, text on hover; hides when nothing needs treatment (`2866258937/MiniHealthPanel/42/media/lua/client/MiniHealth/ISMiniHealth.lua:17`).
- Opens: always on, created for each local player (`MiniHealthInit.lua:7`, `:41`). A click (not a drag) runs `self.infopanel:toggleView(getText("IGUI_XP_Health"))` (`ISMiniHealth.lua:539-543`) where `infopanel = getPlayerInfoPanel(n)` (`:46`).
- Hidden: no, the figure shows. But the click goes to the game's Character window. ZeD never references that window (grep over `42/media/lua`: 0 hits for `characterInfo`, `getPlayerInfoPanel`, `ISCharacterInfoWindow`), so `toggleView` will make the game's own window appear on top of ZeD. By reading only; not seen in play.
- Data: `toggleView` is the only coupling.
- Recommendation: leave the widget as its own HUD piece; on ZeD's side wrap `ISCharacterInfoWindow:toggleView` (or `getPlayerInfoPanel`) so Health opens ZeD's Health tab. Effort S. Why: a small fix that also guards against any other mod that calls the game's Character window directly (Traits Purchase System's pop-up, row 27, and Armor Makes Sense's pad handler, row 26, both do, from places that are hidden under ZeD). The figure could also overlap ZeD's Left or Bottom moodles at the bottom left.

### 9. Map Symbol Size Slider (2,232,588) - id MapSymbolSizeSlider, workshop 2734705913

- Sees: a slider inside the game's map-symbols panel that scales every mark and note (0.066 to 2.266 of the game's scale). Saved per player under `getModData()["MapSymbolSizeSlider_currentScale"]` (`2734705913/Map Symbol Size Slider/42/media/lua/client/MapSymbolSizeSlider/MapSymbolSizeSlider.lua:60`).
- Opens: `ISWorldMapSymbols:createChildren` wrapper.
- Hidden: yes. ZeD draws marks at `ISMap.SCALE` (`ZeD:MapsTab.lua:855` `_previewMark`), so a size saved earlier still applies, but the slider that changes it is gone.
- Data: `ISWorldMapSymbols:ChangeGlobalScale(v)` (`.../MapSymbolSizeSlider.lua:78`) sets `ISMap.SCALE`; `MapSymbolSizeSlider.onSliderChange` (`:56`).
- Recommendation: a slider on ZeD's map toolbar, calling the mod's function when present. Effort S.

### 10. Draw On The Map (2,392,013) - id DRAW_ON_MAP, workshop 2804531012

- Sees: a pencil button; a panel with Draw, Line, Erase, brush size and fill sliders. Free-hand strokes are many small texture symbols along the drag (a stroke is a trail of marks; the symbol cap is raised to 250,000, `.../WorldMapSymbolTool_FreeHandTool.lua:81-100`).
- Opens: pencil and panel added in `ISWorldMap.createChildren` (`2804531012/DrawOnMap/42.13/media/lua/client/DrawOnMap/Patches/ISMap_patch_create_free_hand_ui.lua:19`) and `ISMap.createChildren` (the map item panel, `:47`).
- Hidden: yes. ZeD has its own toolbar and its own tools (`ZeD:MapsTab.lua:1033`).
- Data: the tool classes are `ISWorldMapSymbolTool` subclasses that need the game's `symbolsUI`; the only map call is `symbolsAPI:addTexture(tex, worldX, worldY)` plus colour, anchor and scale (`.../WorldMapSymbolTool_FreeHandTool.lua:111-122`). ZeD can do the same through the map's symbol store the way `_placeAnnotationAt` does (`ZeD:MapsTab.lua:548`).
- Recommendation: a Draw tool on the Maps toolbar (draw, line, erase, size). Effort M to L. Why: a favourite of mappers (2.4M) but it needs a new drag tool, erase by region and an undo for runs of thousands of marks; do it after the small map rows.

### 11. Reorder Containers (2,295,696) and Better Containers (230,673)

- Sees: drag a container button up or down in the strip to set its order, per container; lock buttons stop accidental changes; Better Containers adds customise, categorise and proximity on top (708 Lua files).
- Opens: on the game's container button column (`2901962885/ReorderContainers/42.12/media/lua/client/ReorderContainers/UI/SortableBackpackButton.lua`, `InventoryPage_reorder_backpack_buttons.lua`).
- Hidden: yes, the notes already say ZeD's strip keeps its own order.
- Data: `ReorderContainersService.getSortPriority(player, inventory, page)` (`.../ReorderContainersService.lua:51`), `setSortPriority` (`:60`), lock flags in player data (`:119`). Order is saved inside the container's own object or item data.
- Recommendation: a native feature in ZeD's Loot tab strip, the player's order saved by ZeD; do not read the mod's saved order. Effort M. Why: an order feature is a design call about ZeD's strip, not mod support.

### 12. Smarter Storage (1,242,067) - id SmarterStorage, workshop 3290232938

- Sees: your own name, picture (any item) and colour on a container; presets (weapons, ammo, tools, clothing and so on); copy and paste of a look; a capacity tooltip (`3290232938/SmarterStorage/42/media/lua/client/SmarterStorage.lua:560`).
- Opens: right-click a container button in the game's loot window (`SmarterStorage:addMenuOptions :123`; UI in `SmarterStorageUI.lua`).
- Hidden: yes. It restyles the game's container buttons (`updateSmarterStorageData :573`).
- Data: three keys on the container's object: `SmarterStorage_Name`, `SmarterStorage_Icon` (an item full type), `SmarterStorage_Color` {r,g,b,a}; it also adopts names from "Everything Has a Name" and "Rename Container" (`:600-611`). `SmarterStorageUI.applyToButton(button, name, item, color, page)` (`SmarterStorageUI.lua:1001`) writes them.
- Recommendation: a section inside the Loot tab. First read-only (name, picture, colour on ZeD's container tabs, S), then an editor card (M). Effort S then M.

### 13. Condition On Dash (910,315) - id ConditionOnDash, workshop 3306168142

- Sees: hover text on dash icons: Engine condition, Battery condition and charge, left and right headlight condition (`3306168142/ConditionOnDash/42/media/lua/client/ConditionOnDash.lua:2-28`).
- Hidden: yes, ZeD draws its own dash; it has only an engine warning lamp below 40 (`ZeD:ZeD_Dashboard.lua:181-182`).
- Data: `vehicle:getPartById(...)`, `part:getCondition()`, `vehicle:getBatteryCharge()`. No mod data.
- Recommendation: hover text on ZeD's dash lamps (native). Effort S. Why: the same job as Common Sense's lamp tint, so do both together.

### 14. Moodle Framework (835,536) - id MoodleFramework, workshop 3396446795

- Sees: new moodles added by other mods (nutrition, hygiene and so on) as extra pictures with the same look as the game's.
- Opens: always on. Each is its own element positioned at `x = right edge - MF.xOffset - width`, `y = screen top + MF.yOffset (120)` plus a step for every active game moodle (`3396446795/MoodleFramework/42.20/media/lua/client/MF_ISMoodle.lua:14-16`, `:441-449`).
- Hidden: no, but stranded. ZeD moves the game's column (right under the watch, left, or a row at the bottom; `ZeD:ZeD_Moodles.lua:215` `_place`), and in the bottom setting parks the real column off screen. The framework's moodles keep to the old right-edge rule. Under the right placement they may sit on the watch (by reading; not seen).
- Same family: Companion Dogs puts its stack at the right of the game's column using `MoodlesUI.getInstance():getY()` (`3740052292/CompanionDogs/42/media/lua/client/CompanionDogs_Moodles.lua:665-678`), Lifestyle draws its own `ISMoodles` (`3403870858/Lifestyle/common/media/lua/client/LSMoodleManager.lua:230`), "Moodles in lua" (424,678) is a full rewrite. ZeD's own copy of the column also lists only the game's moodle types (`ZeD:ZeD_Moodles.lua:43` ORDER).
- Recommendation: HUD piece. ZeD's moodle placement adopts the framework's moodles (`MF.MoodlesStorage`) into its column or row, with its hover chip. Effort S to M. Why: moodles are the one thing ZeD only moves, so this fits "moving them around".

### 15. Auto Mechanics (727,921) - id AutoMechanics, workshop 3387539308

- Sees: items in the vehicle mechanics menu: "Auto Mechanics" (train mechanics by installing and removing parts), "Uninstall all", "Continue", and "Inflate all tires" on a tyre; tooltips explain why an item is greyed.
- Opens: wrapped `ISVehicleMechanics:doPartContextMenu` (`3387539308/AutoMechanics/42.21/media/lua/client/AutoMechanics_RISVehicleMechanics.lua:18`), `onRightMouseUp` (`:28`), `addAutoMechanicsButtons` (`:78`).
- Hidden: partly. ZeD's X or right-click on a part runs the game's `doPartContextMenu` (`ZeD:MechanicsTab.lua:721`), so the entries appear in that menu. They are vehicle-wide, not about the part, and the empty-window right-click route is gone.
- Data: `AutoMechanics.analyzeTrainMechanicsAvailability(chr, vehicle)` (`:107`), `getResumeJob(vehicle)` (`:83`), actions `ISVehicleMechanics:onAutoMechanicsTrain(player, vehicle)` (`:44`).
- Recommendation: a section inside the Vehicle tab, header buttons (Train, Uninstall all, Continue). Effort S. Why: the same pattern covers Vehicle Repair Overhaul (2,454,398; heater, lightbar and engine rebuild through `doPartContextMenu`, `2757712197/Vehicle Repair Overhaul/42/media/lua/client/zzz_VRO_Fixing.lua:1841`), Restore Engine Quality and More Car Features, which are already reachable in the part menu.

### 16. Players On Map (802,773) - id POM, workshop 2879960936

- Sees: a coloured dot and a name tag for each other player on the world map and mini-map (multiplayer, and local split-screen); sandbox rules for range, faction only, dead players (`2879960936/PlayersOnMap/42/media/lua/client/PlayersOnMap.lua:24-99`).
- Opens: always on; wraps `ISWorldMap:render` (`:101`) and `ISMiniMapOuter:render` (`:114`); turns the engine's own player dots off while it draws (`:137-161`).
- Hidden: yes, ZeD's map is a different class. No dots, and the engine's own dots follow the engine setting.
- Data: `OnServerCommand("PlayersOnMap","players")` fills the global list (`:131`); `pom_getPlayers()` (shared); `mapAPI:worldToUIX/Y` for position (`ZeD:MapsTab.lua:855` uses the same API).
- Recommendation: an overlay in the Maps tab (`ZeD_WorldMap:render` chain, `ZeD:MapsTab.lua:962`). Effort S. Multiplayer only value.

### 17. Share Annotations (713,637) - id BLTAnnotations, workshop 2815560151

- Sees: a small list at the top left of the map: a tick box for each learned set of notes ("symset") and an x to delete it; the notes appear on the map. "Remember annotations" is an item menu entry on paper that carries them (`2815560151/BLTAnnotations/42/media/lua/client/annotations_client.lua:398`, works in ZeD).
- Opens: `ISWorldMap:instantiate` wrapper adds the panel (`:521`); `ISWorldMap.ShowWorldMap` wrapper applies the saved hidden sets once (`:534`) which ZeD's route skips.
- Hidden: yes. Worse than hidden: the hidden-set state saved earlier is not applied, and once a set is hidden there is no control to bring it back.
- Data: global `BLTAnnotations` (`Lib`): `Lib.getOrCreateModData()` (`:76`, tables `symsets` and `hidden`), `Lib.setSymsetVisible(name, visible)` (`:147`), `Lib.deleteSymset(name)` (`:214`), `Lib.healHidden()`. The symbols live in the same map symbol store ZeD binds to.
- Recommendation: a section in the Maps tab, "Learned notes" with show/hide/delete. Effort S.

### 18. Where Am I? (690,330) - id WhereAmI, workshop 3097650043

- Sees: a header at the bottom of the map with the name of the area (a region name, or "Kentucky, USA" outside any region) (`3097650043/WhereAmI/42.0/media/lua/client/BB_WhereAmI_LocationHeader.lua:17-35`).
- Opens: `ISWorldMap:createChildren` adds it (`BB_WhereAmI_WorldMap.lua:13`); `ISWorldMap.ShowWorldMap` wrapper refreshes the area first (`:24-25`), which ZeD's route skips.
- Hidden: yes.
- Data: `BB_WhereAmI.currentArea` (string), `BB_WhereAmI.CheckPlayerArea()`.
- Recommendation: a line under the Maps tab title, refreshed each time the map opens. Effort S.

### 19. Antibodies (677,369) - id lgd_antibodies, workshop 2392676812

- Sees: a Knox infection window (tabs: condition effects, wound effects, infection effects, hygiene effects, a progress bar) and, when its option is on, a Hygiene tab on the Character window (per body part: body hygiene %, clothing hygiene %, coloured body figure).
- Opens: a "Knox infection" button next to Fitness on the game's Health panel (`2392676812/lgd_antibodies/42.13/media/lua/client/ui/is_health_panel.lua:19-37`, click `:13` = `AntibodiesWindow.show(doctor, patient)`, shown only with a medical file, the diagnose option and enough First Aid, `:50-68`); the Hygiene tab is added in `ISCharacterInfoWindow:createChildren` (`is_character_info_window.lua:7`).
- Hidden: yes. ZeD's Health tab uses a stand-in that never runs `ISHealthPanel:createChildren` (`ZeD:HealthTab.lua:418-431`), so no button; the Character window tab is not shown.
- Data: `AntibodiesMedicalFile.of(player).body:getBodyPartByIndex(i)` with `bodyBlood`, `bodyDirt`, `clothingBlood`, `clothingDirt` (`.../antibodies_hygiene_body_panel.lua:87-95`); the window opens by itself (`antibodies_window.lua:39`), its tabs `:198-201`.
- Recommendation: a section inside the Health tab. Step one: a Knox infection button with the same rules that opens the mod's window (S). Step two: the hygiene list, per part with the body figure colours (M). A full native version of the infection tabs is L and is not worth it while the window works.

### 20. TV & Radio ReInvented (540,843) - id TVRadio_ReInvented, workshop 3420581050

- Sees: a TV with real moving pictures (clips by channel, by hour for channel 203, by tape title for VHS, and static once the broadcast ends, after about 185 game hours: `getWorldAgeHours() < 185`), a VHS slot, merged radio, ham, walkie, CD and car-radio panels (`3420581050/TVRadio Reinvented/42/media/lua/client/RadioCom/RadioWindowModules/RWMMerged*.lua`).
- Opens: it ships a full replacement of the game's file `RadioCom/ISRadioWindow.lua` (same path, so the game's copy is not loaded), and registers `onEquip` (`.../ISRadioWindow.lua:541-548`). ZeD's boot step removes whichever `ISRadioWindow.onEquip` is current (`ZeD:Overrides/RadioWindow.lua:31-40`); because the mod replaces the file there is only one handler, so the removal works (by reading).
- Hidden: yes for the screen. The notes grade this B ("not checked one by one"): ZeD's Radio tab reads any `IsoWaveSignal` (`ZeD:RadioTab.lua:122-157`), which includes TVs, as a radio chassis.
- Data: `RWMMergedTV.getAllVideos()` builds `VideoTexture.getOrCreate(path, 160, 120)` clips on game start (`RWMMergedTV.lua:10-34`); `RWMMergedTV:chooseVideo()` (`:198`) picks the clip from `self.deviceData`, `self.videos`, `self.video`, `self.videoName` only, so it can be called with a stand-in; the picture is `self.video:RenderFrame()` then `drawTextureScaled` (`:300-306`).
- Recommendation: a TV face in the World window Radio tab, using the mod's clips when it is on. Effort S to M. Why: the screen is the one thing no ZeD radio face replaces; the other panels are duplicates.

### 21. Neat Crafting - XP & Mod Display (464,500) - add-on, workshop 3540503606

- Sees: on each recipe the XP it awards and, optionally, the mod it comes from; two extra filters: "only recipes that grant XP", "only mod recipes" (`3540503606/NeatCrafting_XP/common/media/lua/client/Neat_Crafting/XP_NC_FilterBar_ExtraFilters_patch.lua`, `XP_NC_RecipeList_Box.lua`).
- Hidden: yes, it extends Neat Crafting, which ZeD replaces.
- Data: plain recipe calls: `recipe:getXPAwardCount()`, `getXPAward(i)` (`XP_NC_RecipeList_Box.lua:298-300`), `getModID()`, `getModName()` (`:335`, `:467-471`). ZeD's crafting shows neither (grep: 0 hits).
- Recommendation: a native Craft tab feature, no mod needed: XP on the recipe and a "from" line, with two filters. Effort S. Why: 464k players installed this to get exactly this.

### 22. The Only Cure (400,871) - id TheOnlyCure, workshop 3580276809

- Sees: limb amputation (saw, cauterize, clean wound); the Health panel draws the missing limb on the body figure tinted by healing and a prosthesis; dropping a saw on a body part starts the cut.
- Opens: wraps `ISHealthPanel:doBodyPartContextMenu` (`3580276809/The-Only-Cure/42/media/lua/client/TOC/UI/HealthPanel.lua:62`), `ISHealthPanel:render` (`:163`, drawing `:129`), `dropItemsOnBodyPart` (`:44`).
- Hidden: partly. The menu entries should come through ZeD's stand-in call (`ZeD:HealthTab.lua:431`); the figure drawing and the drag route do not.
- Data: `CachedDataHandler.GetHighestAmputatedLimbs(username)` (`HealthPanel.lua:166`), `dcInst:getCicatrizationTime(limb)` (`:144`), `dc:getIsProstEquipped(limb)` (`:157`).
- Recommendation: a section inside the Health tab, amputation marks on ZeD's body figure. Effort M. Why: an amputee's figure showing a full body is wrong information.

### 23. Working Seatbelt (312,061) - id WorkingSeatbelt, workshop 3055029361

- Sees: a seatbelt lamp at the end of the dash's left warning strip (grey; red when the engine runs and the driver is not belted) and a right-click on it for the chime.
- Opens: key to fasten or unfasten (`3055029361/Working Seatbelt/42.0/media/lua/client/WorkingSeatbelt_Events.lua:119`, works); lamp in `createSeatbeltIndicator` (`WorkingSeatbelt_Hooks.lua:107`), chime menu `doContextMenu` (`:70`).
- Hidden: yes, lamp and chime menu.
- Data: `WorkingSeatbelt.onDoSeatbelt(player, bool)`, `SharedUtils.isWearingSeatbelt(character)`, `SharedUtils.getSeatbeltChimeState(vehicle)`, player data `Seatbelt_sbStatus`. High-beam lamp from Nepenthe's High Beams (369,781; `3438126404/Nep High Beams/42.15/media/lua/client/NepHB_highbeams_O7.lua:306`) is the same kind of piece.
- Recommendation: one more lamp on ZeD's dash plates with a right-click for the chime. Effort S to M (the art is the work).

### 24. More Description For Traits (216,426) - id MoreDescriptionForTraits4213, workshop 3623919908

- Sees: trait and occupation tooltips ending with extra lines (the real effects), free recipes and foraging numbers (`3623919908/MoreDescriptionForTraits4213/42.13/media/lua/client/MDFT_CharacterCreationProfession.lua:729`). It also changes the game's creation lists (`:811-857`) and the Character screen's trait icons (`MDFT_TweakTraitTooltip.lua:10-21`).
- Hidden: yes. ZeD reads the plain `traitDef:getDescription()` in the Identity tab (`ZeD:IdentityTab.lua:209`) and the Traits screen (`ZeD:ZeD_MainMenuTraits.lua:249`, `:262`).
- Data: `MDFT.addDescriptionToTooltip(definition, desc)` returns the longer text; options through `PZAPI.ModOptions`.
- Recommendation: call it where ZeD shows a trait or occupation description (Identity hover, Traits screen). Effort S. The older "Detailed Descriptions for Occupations and Traits" (773,566) is only translations and generated scripts, so ZeD shows it already.

### 25. Detailed Skill Tooltips (189,932) - id EURY_DST, workshop 3572846242

- Sees: what each skill level unlocks, in the skill bar's tooltip and on the XP-boost list at character creation (`3572846242/Detailed Skill Tooltips/42.20/media/lua/client/DST.lua:388`, `:408`).
- Hidden: yes. ZeD's Skills tab has no level hover (grep `tooltip|hover` in `ZeD:SkillsTab.lua`: nothing). The creation list hook runs on the game's list (`CharacterCreationProfession:checkXPBoost`), which ZeD calls (`ZeD:ZeD_MainMenuTraits.lua:104`, `:113`) but does not show the row text from.
- Data: `DST.SkillTooltips.appendLevelTooltip(perk, level, text, cumulative)` (`DST.lua:300`), pure.
- Recommendation: a level hover in the Skills tab (design first), the mod's lines appended. Effort S after the hover exists.

### 26. Armor Makes Sense (174,701) - id ArmorMakesSense, workshop 3677430162

- Sees: a Burden view: load, endurance, heat, breathing, melee and sleep costs of worn gear (pips and plain words), a weight-by-area body map, the heaviest items, Take off / Drop / Wear armor buttons, a Help window.
- Opens: a tab put into the game's Character window (`3677430162/ArmorMakesSense/common/media/lua/client/core/ArmorMakesSense_UI.lua:459-497`); if that fails it opens a stand-alone fallback window (`:350`), which does not trigger under ZeD because the tab attaches to the (hidden) window. B on the pad calls `toggleView` on the game's window (`ArmorMakesSense_BurdenPanel.lua:160-169`).
- Hidden: yes.
- Data: `ArmorMakesSense.Core.BurdenView.build({ runtime, options, analysis, covered, heatPending })` (`ArmorMakesSense_BurdenView.lua:494`), a screen-free view model ("No UI calls", `:5`). The snapshot is gathered in `Panel:collectSnapshot` (`ArmorMakesSense_BurdenPanel.lua:194-224`).
- Recommendation: a Burden section inside the Equipment tab (next to the defense dashboard), a tab only if the director wants it. Effort M. Why: the best data layer on the list.

### 27. Traits Purchase System (175,437) - id TraitsPurchaseSystem, workshop 3211693903

- Sees: a window to spend trait points: buy a good trait, pay off a bad one; a block list of traits.
- Opens: only through a pop-up shown when the mouse is over the game's Health button on the left-edge column (`3211693903/TraitsPurchaseSystem/42/media/lua/client/TraitsPurchaseSystem/ISEquippedItem.lua:64`, click `:112-124` calls `TraitsPurchaseSystem_mod.Windows[chr]:toggleWindow()`). No key, no menu.
- Hidden: yes and unreachable: ZeD hides that button.
- Data: `Utils.getCurrentTraitPoints(player)` (`ISTraitsPurchasePanel.lua:98`), `updateList` (`:272`), buy/remove logic `:129-175`, `:409`.
- Recommendation: an Identity tab section with the points and a button that toggles the mod's window (S); a native list from the same calls later (M).

### 28. Traits As Skills (153,861) - id traitsAsSkills, workshop 3784847437

- Sees: a Traits tab right after Skills: evolving traits shown as skill bars with levels and stages, grouped by category, a "see all traits" tick. Other mods can register their own traits (`TAS.Spectrum.registry`).
- Opens: tab added in `ISCharacterInfoWindow:createChildren` (`3784847437/traitsAsSkills/42.0/media/lua/client/TAS/TASUI.lua:30`, `:15`).
- Hidden: yes.
- Data: `TAS.Spectrum.registry`, `getCategory(def)`, `getDisplayName(def)`, `TAS.ClientState.get(def.id)` (`ISTASCharacterInfo.lua:48,179`; `TASClientState.lua:8`), `TAS.Spectrum.getLevelInfo(def, base, netXP)` (`ISTASSpectrumBar.lua:571`); `TAS.ClientState.request()` each frame (`ISTASCharacterInfo.lua`).
- Recommendation: a Character window tab, Traits, after Skills (`addTab` with `after = "skills"`). Effort M. Why: the one candidate that is a real tab, reusing the Skills bars.

### 29. Full Dynamic Scarring System (129,901) - id ScarSystem, workshop 3750907049

- Sees: an "Injury History" tab: date, injury, body part, cause, newest first (`3750907049/ScarSystem/42/media/lua/client/ScarSystem_HistoryPanel.lua:71-95`); the scars themselves are body visuals (`media/lua/client/ScarVisuals.lua`).
- Opens: `ISCharacterInfoWindow:createChildren` (`:112-121`). Hidden: yes.
- Data: only `player:getModData().ScarSystem.history` (`:77`). Recommendation: a section in the Journal tab or under the Health tab's injury list. Effort S.

### 30. True Music B42 (318,666); related and only skimmed: True Music Radio (343,385), New Music (394,908)

- Sees: a boombox / walkman window with cassette and vinyl slots, autoplay and a speaker link. True Music Radio adds a radio terminal (`3100475013/TrueMusicRadio/42.20/media/lua/client/TrueMusicRadio/TMRadio.lua`, 2,268 lines, hooks `ISRadioWindow`). New Music (Tali's) has its own boombox, CD player and walkman windows (`3739256725/Talis New Music/42/media/lua/client/ui/boombox/NMBoomboxWindowHelpers.lua`, `ui/cdplayer/`, `ui/walkman/`). Neither of these two was read past its file list.
- Opens: it replaces `ISRadioWindow.activate` so music players open its own window `ISTCBoomboxWindow` (`3397198968/TrueMusic_b42/42/media/lua/client/RadioCom/ISTCRadioWindow.lua:36`, `ISTCBoomboxWindow.lua:10`); the "Device options" entry on the item (`Context/Inventory/InvContextBoombox.lua:59`) and the world object menu open it.
- Hidden: no for the window. ZeD's Radio tab would show a boombox as a plain radio with no cassette slot (by reading; not verified in play).
- Data: device state in the item's `tcmusic` table (`mediaItem`, `connectTo`, autoplay; `TCRWMMedia.lua:124-201`).
- Recommendation: leave as its own window; revisit a music slot in the Radio tab only if players are seen using the plain face. Effort M.

### 31. Lifestyle: Hobbies (769,404) - id LifestyleHobbies, workshop 3403870858

- Sees: Ambitions (goals with progress, an active list, cooldowns), a beauty score icon, a mirror with hair and make-up, DJ booth and playlists, research and production windows, invention menus, 20+ more.
- Opens: Ambitions from the emote wheel (`3403870858/Lifestyle/common/media/lua/client/ISUI/LSRadialOption.lua:11-24` adds and runs the slice); the rest from world object menus and keys. The beauty icon is a free HUD element (`ISUI/LSBeautyScoreIcon.lua:158`).
- Hidden: mostly no. ZeD keeps the game's emote filler for the inner wheel (HOOK_MAP row 29), so Ambitions should be reachable (by reading).
- Data: `player:getModData().Ambitions` (`LSAmbitionsMenu.lua:40`), manager `LSAmbtMng.AmbitionsMenu` (`ISAmbt/AmbtMng.lua:331`).
- Recommendation: leave as its own window; an Ambitions section in the Journal tab is the one piece worth considering later. Effort M (optional).

### 32. Modern Status (897,099) and Simple Status (1,210,970)

- Sees: draggable status bars or circles for needs (30-odd) (`3451167732/MS/42.13/media/lua/client/MS/StatusWidget_Main.lua:16`); Simple Status is the plain bar version (`2867431511/SimpleStatus/42.20/media/lua/client/ISSSBar.lua`).
- Opens: always on. Modern Status's layout menu (lock, multi drag, icon source, auto-hide, hide the game's moodles) is opened by right-click on the game's Health button (`3451167732/MS/common/media/lua/client/MS/Patch/MS_ISEquippedItem_HealthBtn_GlobalSettings.lua:323-345`).
- Hidden: the bars no; the menu yes, since ZeD hides that button. Its "hide the game's moodles" switch can also fight ZeD's moodle option.
- Recommendation: leave as its own window; a ZeD Settings row that calls the mod's menu. Effort S.

### 33. Beyond Ten - Level 15 Skills (123,224) - id BeyondTen, workshop 3765241705

- Sees: skills continue past 10 on "mastery XP": a 15-slot skill bar, progress to the next mastery rank, bonuses that keep scaling, a tooltip breakdown. Native level stays 10; the extra ranks live in the mod's player data.
- Opens: it rewrites the game's skill bars and Character info panel (`3765241705/BeyondTen/42/media/lua/client/BeyondTen/SkillUI.lua:72-250`: `ISSkillProgressBar:new`, `renderPerkRect :142`, `getXpForLvl :184`, `getPerkXp :195`, `ISCharacterInfo.loadPerk :203`).
- Hidden: yes, and misleading. ZeD's Skills tab treats level 10 as the top (`ZeD:SkillsTab.lua:146-147` getPinData, `:191` progress, `:847` row fill): a player past 10 sees a full bar with no sign of the five more ranks.
- Data: `BT = BeyondTen`; `BT.NATIVE_MAX_LEVEL` 10, `BT.MAX_LEVEL` 15 (`.../shared/BeyondTen/Shared.lua:10-11`); `BT.GetEffectiveLevel(character, perk)` (`:247`), `BT.GetLevelProgress(character, perk)` (`:259`, returns level, current xp, xp needed), `BT.GetMasteryState` (`:231`), `BT.GetMasteryCost` (`:215`). It also keeps Skill Recovery Journal in step (`.../shared/BeyondTen/SkillRecoveryJournal.lua`).
- Recommendation: a section inside the Skills tab: when the mod is on, the level-10 row shows five more pips and the mastery progress. Effort S to M. Why: the numbers are plain; it is also the one mod where ZeD currently shows a wrong picture of the character.

### 34. Medical Meister (281,573) - id P4MedicalMeister, workshop 3173649443

- Sees: nothing of its own; clicking a moodle icon runs the matching action (hungry: eat, thirst: drink, pain: painkillers, bleeding: bandage and so on), with options per moodle.
- Opens: `Events.OnMouseDown / OnMouseUp` (`3173649443/P4MedicalMeister/42.19/media/lua/client/P4MedicalMeister.lua:158,163`). It works out which moodle was clicked from the position of the game's moodle column: `moodlesUI:isPointOver(x, y)` and `getAbsoluteY` (`:176-186`), then `getMoodleType(slot)` (`:189`), then `doAction(moodleType)` (`:212`).
- Hidden: partly. With ZeD's Right and Left settings the game's own column is the one on screen (ZeD only moves it, `ZeD:ZeD_Moodles.lua:215`), and ZeD's layer lets clicks through (`ZeD_Moodles.lua:447-448`), so the hit test should still land (by reading). With the Bottom setting the real column is parked off screen and ZeD draws its own copy row, so the click finds nothing.
- Data: `P4MedicalMeister.doAction(moodleType)` is global.
- Recommendation: in the Bottom row, a click on a moodle calls `P4MedicalMeister.doAction` when the mod is on. Effort S. Why: keeps the mod working in every moodle placement.

## Candidates in detail: screens ZeD also replaces (use one)

These do not need a ZeD surface. Entries from the compatibility notes are marked (notes).

- Clean HotBar (1,587,338, C, notes): replaces `ISHotbar.render`, `setSizeAndPosition`, `onMouseUp`, `getSlotIndexAt` (`3461263912/CleanHotBar/common/media/lua/client/hotbar/cleanhotbar.lua:488,504,563,585`) and `ISEquippedItem:render` (`ceequippeditemstate.lua:187`); it adds a settings button on the hotbar and a durability alert. ZeD parks the hotbar and re-parks it if another mod redraws it (`ZeD:Overrides/Belt.lua:154`). Not worth it: the belt covers hands, hotbar, condition and keys. Use one.
- CleanUI (1,208,122, C, notes): ships full replacements of the game's `ISUI/ISInventoryPage.lua` (3,554 lines) and the container controls files (`3437629766/CleanUI/42.13/media/lua/client/ISUI/ISInventoryPage.lua`, `.../ISUI/InventoryWindow/ISInventoryWindowContainerControls.lua`). Features: container bars, saved drag order, search, sorting, collapsible groups, weight. Two of its ideas (saved container order, search) overlap rows 11 and 6; they are ZeD design calls, not mod support. Not worth it as mod support.
- Equipment UI - Paper Doll (2,884,483, C, notes; discontinued): a side panel with a body-slot doll and a hotbar-slot strip on the game's inventory page (`2950902979/EquipmentUI/42.13/media/lua/client/EquipmentUI/UI/EquipmentPanel.lua:20`; hide-equipped toggle `Patches/ISInventoryPane_hide_equipped_items.lua:7`; key `Keybindings.lua:7` comma). ZeD's Equip tab has a paper doll (`ZeD:EquipDoll.lua`). Not worth it. Same for the standalone continuation (Equipment UI - Standalone, 259,322, not in notes), NeatUI Equipment (170,546, not in notes) and the Inventory Tetris bundle (below).
- Item Condition (1,176,515, C, notes): condition bars on the hotbar and hand slots and the inventory list (`2852309899/qdx_item_condition/42/media/lua/client/qdx/item_condition/UI/ItemConditionHotbar.lua:8`, `ItemConditionEquippedItem.lua:8`). ZeD shows condition on the belt and in lists. Not worth it.
- Item Condition Overlay (435,903, C, notes): condition and remaining-use bars over the game's list and hotbar (`3641048285/ItemCondition_KingEJ/common/media/lua/client/ItemConditionOverlay.lua:918-940`). Not worth it.
- Minimal Sidebar (355,703, C, notes): fades the left-edge column (minified wrapper on `ISEquippedItem.render` and `prerender`, `3642084851/MinimalSidebar/common/media/lua/client/MinimalSideBar.lua`). ZeD hides the column. Not worth it.
- Neat Building (910,209, C, notes): swaps `ISEntityUI.OpenBuildWindow` (`3536052310/Neat_Building/42/media/lua/client/Neat_Building/Base/nb_overrideisentity.lua:6,105`) and ships its own buildable recipes. The recipes show in ZeD's Build tab; the window competes with ZeD's route (`ZeD:Overrides/Stations.lua`). Use one.
- Neat Crafting (1,133,447, C, notes): overrides `ISEntityUI.GetWindowClass`, `OpenWindow`, `OpenHandcraftWindow` (`3502080466/Neat_Crafting/common/media/lua/client/Neat_Crafting/Base/overwrite_ISEntityUI.lua:70,183,247`), the same functions ZeD routes into the Craft tab; whichever file loads last wins. Use one. Its XP add-on is row 21.
- Realistic Dashboard & Gauges (603,954, C, notes): a replacement dashboard ("YourDash") with passenger dash, radio and lightbar controller (`3635591071/RealisticDashboardAndGauges/42/media/lua/client/YourDash/DashboardCore.lua`, `.../Vehicles/ISUI/Z_PatchVehicleDashboard*.lua`). Use one.
- Reorder The Hotbar (2,405,458, C, notes; discontinued): replaces the hotbar drawing and drag-to-reorder (`2903771337/ReorderTheHotbar/42.0/media/lua/client/ReorderTheHotbar/ReorderTheHotbar_ISHotbar.lua:152-421`). ZeD's belt re-parks the hotbar when this mod redraws it (`ZeD:Overrides/Belt.lua:154`). Whether the belt should offer reordering is a design call, not mod support.
- Tidy Up Meister (1,915,283, C, notes): puts items back, including after an interrupted action (`2769706949/P4TidyUpMeister/42.20/media/lua/client/P4TidyUpMeister.lua`, 1,371 lines; options `:39`). ZeD's Put things back is the same job (off by default). Use one.
- Mod Load Order Sorter (1,154,238, B, notes): a Sort button and a sorting-rules panel on the game's Mods screen (`3423660713/ModLoadOrderSorter_b42/42.0/media/lua/client/OptionScreens/ModSelector/MLOS_ModSelector_overrides.lua:58,147`, `MLOS_SortingRulesPanel.lua:17`). ZeD's Mods screen has its own Auto sort on the game's order rules (`ZeD:ZeD_MainMenuMods.lua:902`). Not worth it; custom rules would be a design question.
- The other B and C mods named in the notes are in the shortlist above: Has Been Read (row 2), Proximity Inventory (row 6), KillCount (row 7), Reorder Containers (row 11), Smarter Storage (row 12), Condition On Dash (row 13) and TV & Radio ReInvented (row 20).

## Looked at and set aside

- Swap It (1,981,281): replaces `ISHotbar:activateSlot` and `equipItem` (`2366717227/SwapIt/42.0/media/lua/client/SwapIt Main.lua`), no screen of its own. Behaviour only.
- Manage Containers (1,988,742): item-menu "Configure containers" opens its own window (`2650547917/ManageContainers/42/media/lua/client/ManageContainers/ConfigureContainer/ISConfigureContainerAction.lua`) and adds a handler class to the container controls (`Handlers/TransferAssignedContainers.lua:33`), which ZeD's controls row runs. Works.
- Project Cook (973,826): a Cooking window; its item-menu entry works (`3490188370/Project_Cook/common/media/lua/client/Project_Cook/PJCK_CookingUI.lua:507`), its flyout beside the game's Crafting button on the left-edge column is hidden. Own window; no surface needed. It replaces parts of the craft flow (`ISEntityUI` reads, `PJCK_FrozenCooking.lua`), so one to test, not to build.
- Braven's Achievements (311,125): a list window on a key bind (`3051277957/BravensAchievements/42.0/media/lua/client/BB_Achievements_List_UI.lua`, `BB_Achievements_Client.lua`). Works. A Journal link could be added later.
- Daily Report Journal (124,975): a daily report window on J, auto-shown on waking or sleeping (`2858201402/dailyStatisticsAndGains/42/media/lua/client/dSAG/dSAG_Core.lua:51-73`, key at `:61`; `dSAG_Window.lua`). Works; ZeD binds no J.
- Burd's Survival Journals (295,075): journal items with their own panel from the item menu (`3639628777/BurdSurvivalJournals/42.15/media/lua/client/UI/BurdJournals_MainPanel.lua`). Works.
- Companion Dogs (556,393, A in notes): status window on a key bind, kennel, settings, scan windows; its note goes to Messages. Its moodle stack follows the game's column y (see row 14).
- Computer Mod (222,979), Immersive Solar Arrays (146,907), Realistic Temperature Mod (137,276): windows opened from world objects through menus (`3725497089`, `2969478819/ImmersiveSolarArrays/42.1/media/lua/client/ImmersiveSolarArrays/UI/ISAStatusWindow.lua:1`, `3600401184/RealisticTemperature/42/media/lua/client/RC_AirCon/RC_AirConUI.lua`). Work.
- Building Craft (423,428): a tile-building window on its own key (`3459887404/BuildingCraft/42.0/media/lua/client/BuildingCraftUI.lua:21`). Works; overlaps ZeD's Build tab in purpose.
- Knox Buildworks (131,562): a whole building system (catalog, planning mode, blueprints) with its own keys; its sidebar flyout (`.../UI/Sidebar.lua`) is hidden. Overlaps ZeD's Build tab. Not in the notes; add as C.
- Fitness & Workout Overhaul (1,549,881): overrides `ISFitnessUI:equipItems` (`2940354599/FWO Fitness Workout Overhaul/common/media/lua/client/ISUI/FWOFitnessWorkoutOverhaulUI.lua:2`). ZeD's Health tab reaches the game's fitness UI, so it applies.
- Replace Bandage (1,217,994): wraps `ISHealthPanel.doBodyPartContextMenu` (`2944344655/ReplaceBandage/42.13/media/lua/client/ReplaceBandage.lua:94`) and the bandage item menu. Reaches ZeD's stand-in (`ZeD:HealthTab.lua:431`); the mod briefly swaps `ISContextMenu.get` to capture the menu (`:98-105`), which depends on ZeD's context menu staying compatible (one to test).
- Kilometers Per Hour (486,298): swaps the speed gauge picture to km/h (`2980583716/KilometersPerHour/42.0/media/lua/client/Vehicles/ISUI/KMPH_ISVehicleDashboard.lua`). ZeD's dash already carries speed in both units (`ZeD:ZeD_Dashboard.lua:228-229`).
- Nepenthe's High Beams (369,781): key and wheel slice, plus a lamp on the game's dash; see row 23.
- Detailed Descriptions for Occupations and Traits (773,566): translations and generated scripts only; ZeD shows them as they are.
- Bandits NPC (1,698,036, A in notes): one hidden line, "Bandits killed", on the game's Character screen (`3268487204/Bandits/42.21/media/lua/client/ISUI/BanditCharacterScreen.lua:17`); see row 7. Its Bandit event markers (`BanditEventMarkers.lua`) are free HUD pieces.
- Lethal Stealth (289,589): a posture HUD (`3531611692/LethalStealth/42/media/lua/client/ISUI/LTS_Hud.lua`) and small marks on skill bars (`LTSBuffs/LTSBuffsIndicators.lua`). HUD works; the marks are minor.
- Bigger Character Avatar (210,707): enlarges the game's Character screen avatar (full file replacement `XpSystem/ISUI/ISCharacterScreen.lua`). Nothing visible under ZeD; no harm.
- TwisTonFire - Better Character Info (274,418; not in notes): rebuilds the game's Character screen (`3488600400/TwisTonFire - BetterCharacterInfo/42.20/media/lua/client/ISCharacterScreenPatch_v16.lua`, 2,605 lines) and opens a floating avatar window at player creation (`TTF_BCI_FloatingAvatarUI.lua:1319-1347`). The floating avatar may still show; the rest is hidden. It also redefines `ISUI3DModel` with all the game's methods (`ISUI/BetterUI3DModel.lua`), used by ZeD's identity and equip figures; a near copy, low risk, one to watch. Add as C.
- Inventory Tetris (300,701; not in notes): a grid inventory replacing the game's inventory windows (`3397561666/InventoryTetris/42.13/media/lua/client/InventoryTetris/...`, 40+ UI files, its own containers' capacity rules in `Patches/Core/InventoryTetris_disable_carry_capacity.lua`). Both rules and screen conflict with ZeD. Add as C.
- Equipment UI Standalone (259,322), NeatUI Equipment (170,546), Neat Rocco's UI (201,787), Better Containers (230,673): inventory, equipment, character and vehicle screens ZeD replaces. Add as C. Neat Rocco's UI touches the Health panel, mechanics window and radio window together.
- Vehicle Seat UI (KI5) (226,643; not in notes): a replacement seat window (`3501302358/VehicleSeatUIKI5/42/media/lua/client/Vehicles/ISUI/ISVehicleSeatUI_KI5.lua`); ZeD's seat chooser takes the game's `onShowSeatUI` first (`HOOK_MAP.md` row 4). Add as C.
- This Is Your Life (288,493, work in progress): replaces the character creation flow (hometown postcards, origin, profession and trait pages) by overriding the same `setVisible` calls ZeD redirects (`3773911887/ThisIsYourLife/42/media/lua/client/ThisIsYourLife/TIYLFlow.lua:23-25,321,371`). This one is more likely to break than hide: both flows claim the same screens. One to test, not to build.
- Project A-Life (298,445), DebugMenu (205,397), Vehicle Repair Overhaul (2,454,398, see row 15), Auto Cook and similar action mods: no screen of their own that ZeD hides.
- Skipped on purpose: pure content (items, clothes, tiles, vehicles), libraries (Starlit Library, TchernoLib, Elyon Lib, NeatUI Framework), and mods that only add context-menu entries.

## Surprises worth the director's attention

1. Mini Health Panel (2.45M) pops up the game's own Character window on top of ZeD when clicked, because ZeD never touches that window (`ISMiniHealth.lua:543`, `getPlayerInfoPanel` 0 hits in ZeD). By reading only; worth one look in play. One small guard in ZeD fixes the class.
2. ZeD has no haircut or beard trim in game. Not a mod problem, but three mods ride on it.
3. Share Annotations can leave notes hidden for good: its saved "hidden" sets are applied only when the game's map opens, and the control to unhide is on the game's map.
4. Traits Purchase System is unreachable under ZeD (its only door is a hover pop-up on a button ZeD hides). Same for Modern Status's layout menu.
5. Common Sense's ammo count can keep the whole left-edge column alive if a gun is in hand at start (ZeD only hides the column when nothing else is visible on it at frame 30).
6. TV & Radio ReInvented replaces the game's radio window file by path, so ZeD's boot step removes the one equip handler there is. That works, but it means whichever mod replaces a game file decides what ZeD's hooks attach to; Neat Crafting and Neat Building override the same craft and build openers ZeD routes, and the last file loaded wins.
7. This Is Your Life and CleanUI replace game files ZeD relies on (character creation screens; `ISInventoryPage` and the container controls). Those two are more likely to break than to hide.
8. Beyond Ten is the one case where ZeD draws a wrong character: a skill past level 10 shows as a full bar and nothing more (`ZeD:SkillsTab.lua:146,191,847`).
9. Medical Meister depends on where the game's moodle column sits. It keeps working with ZeD's Right and Left moodle settings and stops with the Bottom setting (by reading).
