# ZeD-GUI complexity audit, November 20 2026

Report only. No game code was changed, nothing was committed, the game was not launched. Read from the working tree at HEAD 531e39a82 (beta 21 as shipped, plus later docs).

## Summary (six lines)

1. The mod carries about 3,800 lines of code that nothing runs any more (about 1.5 percent of its 259,000 lines), plus 21 old pictures and about 150 unused phrases in each of the 28 language files. All of it can go before 1.0 at low risk.
2. The three biggest pieces: generated data left over from the first watch, radio and siren art (1,018 lines), an early parts library the windows stopped using (about 1,280 lines), and the plain dashboard strip the Style switch retired (about 690 lines with the siren's plain card).
3. The eight old Simple switches can be deleted outright, not just hidden. Nothing reads their values, and the game keeps old settings lines it does not recognize without harm.
4. The same small helpers are written over and over (the "is the pointer in this box" test 42 times, a file reader about 30 times, "is this mod on" 30 times). One shared copy of each removes about 600 lines and a class of small mistakes.
5. Players see 56 settings rows today (64 exist). The proposal brings that to 42 rows: drop the eight dead switches, show related switches as one control, and hide five rows that already have another way in. No saved setting changes meaning.
6. Found on the way: two real bugs (Lite picked from the controller wheel leaves the extras on with no row to turn them off; the preset can read Custom for a reason the player can no longer see) and four places close to the game's 200-variable limit that must not grow.

## Do these first (the ten safest, biggest deletions)

| # | What | Where | Lines saved | Risk |
|---|---|---|---|---|
| 1 | The never-created parts classes: ZeD_ScrollList, ZeD_TabPanel, ZeD_ItemGrid, ZeD_Modal, ZeD_ScrollPanel, ZeD_TextInput, ZeD_Tooltip, ZeD_ZoneList | Organisms.lua:1837-2641, Molecules.lua:675-783, Atoms.lua:1105-1160, ZeD_ZoneList.lua (whole file) | about 1,280 | Low. Trim their names from Overrides/TextScale.lua:257-259 and the ZeD_ZoneList row in FEATURE_MAP.md:1070 |
| 2 | The three generated tables nothing reads: WatchPlates.lua, RadioPlates.lua, SirenPlate.lua, and their old art folders textures/ZeD/dash (10 files, 1.4 MB) and textures/ZeD/watch (9 files, 76 KB) | 42/media/lua/client/ZeD/, 42/media/textures/ZeD/ | 1,018 and 19 pictures | Low. rt_vehicles.lua:384 asserts ZeD.SirenPlate is loaded and rt_coverage_plumbing.txt:13-15 names the three files: edit both in the same commit |
| 3 | The plain dashboard strip and the siren's plain card (unreachable since dashSimple() returns false) | ZeD_Dashboard.lua:852-869, 1454-1468, 1549-1574, 1586-1622, 1662-2160, 2188-2190, 2253-2256; ZeD_SirenController.lua:169-175, 205-277 | about 690, and 45 phrases | Low to medium. Four QA sims stub dashSimple to drive the strip (section 7); they go with it |
| 4 | The eight retired option objects, their preset rows, name keys and the RETIRED list | Settings.lua:280-288, 618-624, 630-633, 643-646, 654-657, 667-670, 678-681, 688-691, 762, 777-779, 818-819, 832, 837, 1035; ZeD_MainMenuOptionGroups.lua:166, 435 | about 110, and 19 phrases | Low, if the preset rows go in the same change (see BUG 2 and item 1.1) |
| 5 | 149 phrases no Lua reads (139 never named, 10 only defined), in each of 28 language files | 42/media/lua/shared/Translate/*/UI.json | about 4,100 JSON lines | Low. Run i18n_guard after |
| 6 | 41 functions whose name appears once in all the Lua (the definition) and in no QA script | list in 1.6 | about 440 | Low |
| 7 | The beta 6 one-time repair | Settings.lua:955-992 and the call at 997 | 40 | Low. It ran, and marked itself done, on the first launch of any build since Nov 6 |
| 8 | Dead ends inside Settings.lua: cycleNext, the character's ZeD_Gamepad copies nothing reads, the second copy of liveIdx, the unused exports | Settings.lua:1328-1344, 1162-1172, 1179-1184, 1046-1053, and 176, 532, 98, 317, 840-841, 560 | about 60 | Low. QA scripts read glyphOption (10 files) and ADDITION_PRESETS (9 files): keep those two or fix the scripts |
| 9 | The first ZeD_CharacterWindow.openTab (replaced at load by Overrides/CharacterInfo.lua:60) and the feature map's own dead list (ActionMap.fromKey, getBinding, getHoldConfig, QuickWheel.addGroups and openGroup, ItemActionManager.registerObserver) | ZeD_CharacterWindow.lua:4118-4153, Input/ActionMap.lua:325 and on, ZeD_QuickWheel.lua:292 and 296, ItemActionManager.lua:41 and on | about 150 | Low |
| 10 | Strays inside the mod folder: body/originals (36 files), body/originals-pre-s45 (19), test_check.png, test_fluent.png, four .py, one .pyc and one .ps1 under 42/media | 42/media/textures/ZeD/, 42/media/fonts/ | 57 pictures, 6 tool files | Low. The Workshop staging already leaves out the originals folders and the tool files; the two test pictures do ship today |

Together: about 3,800 lines of Lua, about 4,100 lines of JSON and 80 files.

## BUGs passed on the way

- **BUG 1: Lite picked from the controller wheel keeps the extras on.** ZeD_DpadWheels.lua:580-583 sets lookStyle through Z.option (ZeD_DpadWheels.lua:501-506), which calls setValue and saves but never runs lookStyle.onChange (Settings.lua:943-945), the only place the additions are put back to Vanilla. ZeD setup and the first-launch window both do it (ZeD_MainMenuWelcome.lua:98 calls pickAdditionsPreset by hand). Failure: a player on Vanilla Plus opens the Select wheel, picks Lite. The ammo box on the belt, read marks, Messages toasts and the rest stay on, and ZeD setup now hides the whole Additions group in Lite (ZeD_MainMenuOptionGroups.lua:167, 438), so there is no row to turn them off without going back to Full. ZeD.Settings.loadSetup (Settings.lua:1384) has the same gap for a setup file that says Lite. Fix: one ZeD.Settings.setLookStyle(i) that every caller uses.
- **BUG 2: the preset reads Custom for rows nobody can see.** The Vanilla Plus and Vanilla Accessible presets still list the six hidden switches (Settings.lua:832, 837), and presetOf (Settings.lua:847-856) compares them. Failure: a beta 20 player on Vanilla Plus who had set only the watch to Simple (watchStyle = 2) opens beta 21. The watch switch is gone and does nothing, every visible row matches Vanilla Plus, yet the Preset control reads Custom, and stays there until they pick a preset again. Fix: delete the six ids from IDS and PRESETS (do-first item 4).
- **Trap, not yet a bug:** if the eight option objects are deleted but their rows are left in PRESETS, read(id) returns nil for them and no player ever matches Vanilla Plus or Vanilla Accessible again. Delete both in one change.
- **Dead condition (harmless today):** ZeD_MainMenuMods.lua:1249 reads "if not simple or lite". Since modsSimple() is lite(), this is always true. The comment above it describes a difference between Simple and Lite that no longer exists.
- **Dead branches (harmless today):** ZeD_Watch.lua:531-540. _plain runs only when W.simple() is true, and W.simple() and W.lite() (ZeD_Watch.lua:489, 491) are now the same answer, so the two branches after "elseif W.lite()" (the Start, Speed, Alarm and Set buttons of the old Simple watch) can never run. The phrases UI_ZeD_WatchPlain_Start, Pause and SpeedBtn die with them.
- **A decision to confirm, not a bug:** in Lite the car radio shows as a plain card (ZeD_CarRadio.lua:101-104 asks devicesSimple) while the siren controller next to it stays the pixel prop and the seats keep the pop-out (ZeD_SirenController.lua:214 and ZeD_SeatPopout.lua:109-112 ask dashSimple, hard-wired false). That follows the beta 21 note at Settings.lua:659-661, but it is two forms on one screen.

## How this was measured

- Line and function sizes: a PowerShell 7 script over every .lua under 42/media/lua (356 files, 12,468 functions). A function runs from its opening line to the first "end" at the same indent. Declared locals are counted the way the game's compiler counts them in debug mode: every local name, every local function, each loop's variables plus three hidden ones, and the parameters, with nested functions counted on their own.
- "Nothing calls it": grep over 42/media/lua for the name, then over ZeDUI/tools/qa. Where QA scripts use something the mod does not, the item says so.
- Phrases: every key in EN/UI.json checked against every UI_ZeD_ word in the Lua, in one pass. A key counts as used if it appears as a whole word, or if a quoted prefix glued with ".." covers it ("UI_ZeD_Act_" .. name covers 279 keys), or if its name without a glued ending ("Tip") is used.
- Pictures: each file's name looked for in the Lua and scripts, then its folder's path.

---

# 1. Dead code

## 1.1 The eight retired option objects (Settings.lua)

What: actionBar (284-288), beltStyle (621-624), devicesStyle (630-633), watchStyle (643-646), dashStyle (654-657), guideStyle (667-670), modsStyle (678-681), identityStyle (688-691). Each is still built and registered, then hidden by G.RETIRED (ZeD_MainMenuOptionGroups.lua:166, 435).

Evidence: `grep -rnE "actionBarOption|beltStyleOption|devicesStyleOption|watchStyleOption|dashStyleOption|guideStyleOption|modsStyleOption|identityStyleOption" 42/media/lua` finds only the eight assignment lines in Settings.lua. The only other mention of the ids is the RETIRED list. No helper reads a value: devicesSimple, watchSimple, guideSimple, modsSimple and identitySimple return lite() (Settings.lua:636-694), dashSimple returns false (658-662), ZeD_Belt.lua:75-77 and ZeD_ActionBar.lua:526 ask lite() directly.

The comment at Settings.lua:592 says they stay so "a save from before keeps reading". That is not needed: the game files a line it has no option for under OtherOptions and writes it back untouched (vanilla PZAPI/ModOptions.lua, load(): "table.insert(PZAPI.ModOptions.OtherOptions, line)"). Options are stored by id, so removing eight does not move any other option's saved choice.

Also goes with them: their nameKeys entries (762, 777-779); the six style ids in IDS (818-819), in the two presets (832, 837) and in the old-save block (1035); G.RETIRED and its loop. On the game's own Mods page (Safe mode, or the options screen handed back) these eight rows still show today and do nothing; deleting them fixes that too.

Phrases that die with them (zero uses outside Settings.lua): UI_ZeD_Settings_ActionBar, ActionBarTip, ActionBarVerbose, ActionBarSimple, Belt, BeltTip, BeltFull, Immersive, Devices, DevicesTip, WatchStyle, WatchStyleTip, Dash, DashTip, GuideTip, Mods, ModsTip, Identity, IdentityTip (19; UI_ZeD_Settings_Guide has one other use and stays).

Lines saved: about 110 in Lua, 19 keys in 28 files. Risk: low. Settings.lua's file-level local count also drops by 8 (it is at 177 of 200, see section 4).

## 1.2 The Simple helpers that now all say the same thing

What: ZeD.Settings.devicesSimple (17 call sites), watchSimple (1 real), guideSimple (1), modsSimple (1), identitySimple (1), dashSimple (3), ZeD.Belt.simple (2), ZeD.Watch.simple and ZeD.Watch.lite, StationAppliance SA.simple, ZeD_Dashboard D.simple, ZeD_SirenController S.simple, ZeD_SeatPopout S.immersive, ZeD.Molecules.lite, and four private isLite / liteOn / liteDesk helpers. On top of that the guard "ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()" is written out 13 times in 12 files.

Proposal: one ZeD.lite() next to ZeD.tr in shared/ZeD/Tr.lua or Tokens.lua (false until Settings loads). Every helper above becomes a call to it; dashSimple, D.simple, S.simple and S.immersive are deleted with the code they guard (1.3). Lines saved: about 40. Risk: low, a mechanical sweep; the release test's rt_lite covers it.

## 1.3 The plain dashboard strip and the siren's plain card

What: ZeD_Dashboard.lua's "THE SIMPLE DASH" (heading at 1454). D.simple() (1468) is the only gate, read once at 2188 and used at 2190 and 2253-2256. It returns ZeD.Settings.dashSimple(), which returns false (Settings.lua:658-662).

Dead ranges: 852-869 (_plainControl), 1454-1468, 1549-1574 (PLAIN_ sizes, lamp order and names), 1586-1622 (_plainPlan), 1662-2160 (_pair, _heatTemp, _ignitionWord, _radioLabel, _plainLabel, _radioLine, _clockText, _climateText, _cell, _distText, D.plainSpeed, _plainCells, _plainItems, _radioItems, _flow, _plainBig, _plainReadouts, _plainRowName, _plainButtons, _plainLamps, _plainLampHover, _plain). Live code inside that stretch, to keep: D.addExtra to D.extraMarks (1483-1533), _hitEnabled (1575-1585, used at 2269), _pubState and D.applyPublished (1625-1661).

Evidence: for each name above, `grep -c` outside lines 1454-2160 of the file is 0 (only _plainControl's definition at 852 and a comment at 394), and no other file names them. QA only: vskdash_sim.lua:609 reads D._plainPlan, zedqa_b8_dash.lua calls D.plainSpeed.

The siren: ZeD_SirenController.lua:169-175 and 205-277 (S.simple, SWITCH_KEYS, _plain, the overlay at 277), gated the same way.

Phrases: 45 of the 47 UI_ZeD_DashPlain_ keys (Odometer and Trip are still used at ZeD_Dashboard.lua:595), and the English defaults table that repeats them at 1534-1548.

Lines saved: about 615 in the dashboard, 75 in the siren. Risk: low to medium. The strip is 500 lines of honest work; if the director might bring a plain dash back, tag the commit before deleting. ZeD_Dashboard.lua's file-level locals (151) drop by about 30.

## 1.4 Whole files nothing reaches

The game loads every file under media/lua/client by itself, so "no require" does not prove a file dead. The test used: nothing outside the file names the table or class it defines.

| File | Lines | Evidence | Note |
|---|---|---|---|
| WatchPlates.lua | 806 | `grep -rn "WatchPlates" 42/media/lua` finds only the file itself. Its own header: "No ZeD Lua reads this table at present" | Generated by tools/plates/anchors2lua.pl. ZeD_Watch draws from ZeD.PhysPx.plates |
| RadioPlates.lua | 195 | `grep -rn "RadioPlates"`: only the file itself | Generated by bake_radio_plates.py. The radios draw from PhysPx (PhysPx.lua:7471) |
| SirenPlate.lua | 17 | `grep -rn "SirenPlate"`: only the file itself | rt_vehicles.lua:384 checks that it is loaded, which proves only that the file exists |
| ZeD_ZoneList.lua | 306 | `grep -rn "ZeD_ZoneList"`: a comment in Molecules.lua:2451 and the class-name list in Overrides/TextScale.lua:258. Never created. FEATURE_MAP.md:68 and :1070 already say DEAD | |
| TestInventory.lua | 470 | Dev bench on F6. stage_workshop.ps1:131 leaves it out of the Workshop build | Fine as it is. Note it binds F6 with no debug check in the dev copy |

The old art that belonged to the three plate tables: 42/media/textures/ZeD/dash (10 files, 1.4 MB: radio_army, radio_ham, radio_hammake, radio_makeshift, radio_premium, radio_valutech, siren_plate, siren_glow, siren_knob, siren_led) and 42/media/textures/ZeD/watch (9 files, 76 KB). Evidence: `grep -rnE "textures/ZeD/dash/|ZeD/watch" 42/media/lua` finds nothing; the live plates of the same names load from ZeD/physpx/. Risk: low, but look at a radio, a watch and the siren once in game after deleting, since the picture names repeat in physpx.

## 1.5 The early parts library (never created)

These ISPanel classes were the first component library. The windows moved to drawn-in-place molecules (ZeD.Molecules.drawButton, ScrollbarState) and nothing creates the classes any more.

| Class | Where | Lines | Evidence (grep for `Class:new(`, `Class.`, and its alias, outside its own definition) |
|---|---|---|---|
| ZeD_ScrollList | Organisms.lua:1837-2114 | 278 | none |
| ZeD_TabPanel | Organisms.lua:2115-2242 | 128 | none |
| ZeD_ItemGrid | Organisms.lua:2243-2351 | 109 | none |
| ZeD_Modal | Organisms.lua:2352-2472 | 121 | ZeD_Modal.show is never called; prompts go through ZeD_Prompt (69 call sites) |
| (a note that the old context menu moved) | Organisms.lua:2473-2484 | 12 | comment only |
| ZeD_ScrollPanel | Organisms.lua:2485-2641 | 157 | none |
| ZeD_TextInput | Molecules.lua:675-783 | 109 | ZeD.Molecules.TextInput never read. ZeD_TextEntry and ZeD_SearchField are the live ones |
| ZeD_Tooltip | Atoms.lua:1105-1160 | 56 | ZeD.Atoms.Tooltip never read. Balloon.lua is the one hover box |
| ZeD_ZoneList | ZeD_ZoneList.lua | 306 | above |

That is the last 805 lines of Organisms.lua (30 percent of the file), with nothing else defined in the stretch (checked: 37 functions, all methods of those five classes).

Two more are down to one caller each and could follow: ZeD_Button (Molecules.lua:451-525, used once at ZeD_CharacterWindow.lua:4704) and ZeD_Dropdown (Molecules.lua:1499-1715, used once at ForagingTab.lua:761, while CraftingCore.lua:1418, Stations.lua:538 and ZeD_MainMenu.lua:1325 each redraw its look in place). Those are section 3 work, not deletions.

Lines saved: about 1,280. Risk: low. After it, trim the eight class names from the list at Overrides/TextScale.lua:257-259.

## 1.6 Functions defined and never named again

41 module functions whose name appears exactly once in all the Lua and in no QA script (about 440 lines). The larger ones:

- Molecules.lua:3379 drawSortStrip (85 lines), 3186 drawProtZonePair (52), 4070 drawCraftActionStrip (43), 980 drawStatChip (29), 4577 drawStatusChip (28), 2275 drawDataRow (15)
- ZeD_Keyboard.lua:588 askClose (21), JournalTab.lua:866 _measureRecipeContent (20)
- Atoms.lua:1534 drawScrollThumb (15), 1196 hoverBoxPlace (14, "older callers"), 176 drawHeading, 189 drawStat; AtomExtensions.lua:128 drawAccentRing (12), 472 drawPillButton (11)
- ZeD_Admin.lua:463 openInventory (10), ZeD_RadioOps.lua:827 drawDisplay (8), ZeD_SurvivalGuide.lua:500 _rulesListRaw (8)
- ZeD_ActionBar.lua:623 drawVerbose, ZeD_Lists.lua:545 createWith, ZeD_Restock.lua:107 outfitWorn, EquipmentTab.lua:1253 dragBusy, Organisms.lua:1767 setTitleStats, CraftingCore.lua:1871 renderSortMenu and 1889 closeShowMenu, MapsTab.lua:640 setPaper, ZeD_MainMenuWelcome.lua:52 tutorialDone, ZeD_TicketCards.lua:946 mineHelp

Leave alone: the six one-line ZeD_Prompt stubs at ZeD_Prompt.lua:371-380 (setNumberOfLines, setValidateFunction and so on). They copy the game's text box so another mod's call does not fail.

Ten local functions are defined and never called (18 lines): InventoryRenderer.lua:2368 dRB, 2380 aSec, 2386 aIcon; FishingWall.lua:37 nowMs; ObjectCardTrack.lua:20 and ObjectCardTrough.lua:27 col; ZeD_MainMenuTerms.lua:35 ms; ZeD_SeatPopout.lua:95 sound; ModSupport/SPNCC.lua:76 txt; ModSupport/traitsAsSkills.lua:301 rowH. The three in InventoryRenderer sit inside renderItemList and each costs a slot against the 200 limit.

Another 26 functions are named only by QA scripts (qa hooks and probes); they are fine.

From the feature map's own dead list (FEATURE_MAP.md:60-69), re-checked today and still dead: ContextMenuRegistry.togglePin (saved pins apply, nothing sets one), ItemActionManager.registerObserver (no caller), QuickWheel.addGroups and openGroup (ZeD_QuickWheel.lua:292, 296, defined only), ActionMap.fromKey, getBinding and getHoldConfig (Input/ActionMap.lua:325, 342, 352, defined only) and the strip_, layout_mode and inspect actions (ActionMap.lua:104-129), the OnZeDThemeChanged event (Tokens.lua:1322-1324, fired, no listener), the first openTab (ZeD_CharacterWindow.lua:4118-4153; its own comment says the later definition wins).

Small dead fields: ZeD_Admin.lua:41 WATCH_IDLE_MS ("read nowhere"), ZeD_CharacterWindow.lua:4468 _journalSubTabZones, ReadMarks.lua:264 DOT_W, ContainerControls.lua:825 HINT_MS, ZeD_FocusPaint.lua:289 FP.paint (a second name nothing uses), ContainerControls.lua:1077 (a stub "kept so older callers draw nothing").

## 1.7 Dead ends inside Settings.lua

| What | Where | Evidence | Lines |
|---|---|---|---|
| cycleNext | 1328-1344 | Its own comment: "Nothing in ZeD calls it now". grep: 0 in the mod, 1 QA file | 17 |
| The character's copy of the glyph and input-lock picks | 1162-1172, 1179-1184 | `grep -rn "ZeD_Gamepad" 42/media/lua`: four lines, all writes. The comment at 1162 says nothing reads it | 15 |
| pickedIdx | 1046-1053 | Word for word the same as liveIdx at 447-450 | 8 |
| ZeD.Settings.save, saveNow | 105, 1358 | Two names for saveModOptions | 2 |
| Exports nothing reads: statusKeys (176), hiddenActionsKeys (532), inputLockKeys (98), sizeKeys (96), glyphKeys (97), additionsPresetOption (560), ADDITION_IDS (840) | | 0 uses in the mod; inputLockKeys and additionsPresetOption 1 QA file each, ADDITION_IDS 5 | 7 |
| scaleStepRetired's "0.5x, not offered in the beta" | 205-212 | A beta-only rule; at 1.0 either offer 0.5x or remove the item's special case | decide |

Keep: glyphOption (10 QA scripts drive it) and ADDITION_PRESETS (9 QA scripts read it).

## 1.8 ZeD setup rows hidden forever

- The eight RETIRED rows (1.1).
- Nothing else is hidden forever. The Additions and Chords groups are hidden only while Lite is on (G.LITE_HIDES, ZeD_MainMenuOptionGroups.lua:167).
- Four phrases for groups that no longer exist are in the unused list: UI_ZeD_Options_ZedForms, ZedMessages, ZedPutBack, ZedSandbox.

## 1.9 Phrases (UI.json)

EN/UI.json has 6,951 keys, all UI_ZeD_. Result:

| | Keys |
|---|---|
| Read by an exact name in the Lua | 6,074 |
| Covered by a glued prefix such as "UI_ZeD_Act_" .. name (33 prefixes; the short ones were checked against their call sites) | 724 |
| Covered by a glued ending (the screen switches' "Tip") | 4 |
| Only ever defined in a Lua defaults table, never read | 10 |
| Zero appearances in the Lua | 139 |

So 149 keys are unused today, and each is carried in 28 language files (DE, FR and RU hold 6,830 of the 6,951). After items 1.1, 1.3 and the watch branches, another 19 + 45 + 3 = 67 follow.

The 10 defined-only keys: UI_ZeD_Radio_TwoWayBase, UI_ZeD_Radio_TwoWayPortable, UI_ZeD_Status_Danger, UI_ZeD_Status_Info, UI_ZeD_Status_Warning, UI_ZeD_ModDesc, UI_ZeD_ModName, UI_ZeD_NoResults, UI_ZeD_RadioPrompt_Move, UI_ZeD_Siren_PromptTurn. (UI_ZeD_ModName and ModDesc may be read by the game for the mod list; check before deleting those two.)

The first 100 of the 139 with zero appearances, with their line in EN/UI.json (UI_ZeD_Settings_BeltFull at line 2440 is the 139th; a comment in the Lua hid it from the first pass):

UI_ZeD_Animals_BtnCreateZone (299), UI_ZeD_Animals_CreateZoneHint (301), UI_ZeD_Animals_NoEligible (359), UI_ZeD_Animals_NoEligibleHint (360), UI_ZeD_Animals_NoZones (361), UI_ZeD_Animals_Overview (363), UI_ZeD_Animals_RemoveZonePrompt (370), UI_ZeD_Appliance_Empty (419), UI_ZeD_Belt_Both (439), UI_ZeD_Card_Level (487), UI_ZeD_Craft_BadgeNeeds (595), UI_ZeD_DescEdit_Discard (755), UI_ZeD_Doll_Under (842), UI_ZeD_Farm_NeedSeeds (921), UI_ZeD_Farm_NeedShovel (922), UI_ZeD_Farm_NeedSpray (923), UI_ZeD_Farm_NeedWater (924), UI_ZeD_Fire_ConfirmTakeApart (946), UI_ZeD_Fire_FuelFull (948), UI_ZeD_Fire_NeedFuelFirst (956), UI_ZeD_Fire_NeedFuelItems (957), UI_ZeD_Fire_NeedGasTank (958), UI_ZeD_Fire_NeedLighter (959), UI_ZeD_Fire_NeedTank (962), UI_ZeD_Fluid_ConfirmEmpty (978), UI_ZeD_Hair_HintMouse (1095), UI_ZeD_Hair_HintPad (1096), UI_ZeD_Hair_OutOfReach (1108), UI_ZeD_Hair_OutTitle (1109), UI_ZeD_Hutch_HenSitting (1212), UI_ZeD_Hutch_PutInNeeds (1219), UI_ZeD_Inv_OrderLine (1256), UI_ZeD_Inv_OrderWt (1257), UI_ZeD_MMHelp_PadRow (1262), UI_ZeD_Journal_PagePick (1388), UI_ZeD_Lock_NeedCode (1427), UI_ZeD_Lock_NeedCombo (1428), UI_ZeD_Lock_NeedKey (1429), UI_ZeD_Lock_NeedsLock (1430), UI_ZeD_Lock_NeedsRemove (1431), UI_ZeD_Lock_NeedUseCombo (1432), UI_ZeD_Lock_NeedUsePad (1433), UI_ZeD_Lock_StatusNoCombo (1442), UI_ZeD_Lock_StatusNoKey (1443), UI_ZeD_Lock_StatusZeroCode (1450), UI_ZeD_MapKey_Secondary (1541), UI_ZeD_Mods_RuleAfter (1720), UI_ZeD_Mods_RuleBad (1721), UI_ZeD_Mods_RuleBefore (1722), UI_ZeD_Mods_RuleNeeds (1724), UI_ZeD_Mods_RuleNone (1725), UI_ZeD_Mods_RuleSoft (1726), UI_ZeD_Mods_BtnKeepOn (1904), UI_ZeD_Msg_Copy (1964), UI_ZeD_Msg_Help (1973), UI_ZeD_Options_GoBack (2048), UI_ZeD_Options_HelpSpecial (2057), UI_ZeD_Options_KeepEditing (2058), UI_ZeD_Options_ZedForms (2119), UI_ZeD_Options_ZedMessages (2121), UI_ZeD_Options_ZedPutBack (2122), UI_ZeD_Papers_StateUnread (2140), UI_ZeD_Power_NeedCan (2204), UI_ZeD_Power_NeedDisconnected (2206), UI_ZeD_Power_NeedElecPlug (2207), UI_ZeD_Power_NeedElecPlugFix (2208), UI_ZeD_Power_NeedElecUnplug (2209), UI_ZeD_Power_NeedElecUnplugFix (2210), UI_ZeD_Power_NeedOffConnect (2212), UI_ZeD_Power_NeedOffDisconnect (2213), UI_ZeD_Power_NeedScrap (2214), UI_ZeD_Prompt_Search (2239), UI_ZeD_RadioPrompt_Dpad (2285), UI_ZeD_Reader_KeepIt (2308), UI_ZeD_Seat_NumberGetOut (2369), UI_ZeD_Siren_Dpad (2508), UI_ZeD_TAS_Bad (2570), UI_ZeD_TAS_Good (2578), UI_ZeD_Trough_ConfirmEmpty (2655), UI_ZeD_Trough_NeedAddFood (2659), UI_ZeD_Trough_NeedAddWater (2660), UI_ZeD_Veh_CantDo (2686), UI_ZeD_Veh_HdrInfo (2706), UI_ZeD_Veh_InspectThe (2709), UI_ZeD_Veh_InspectToRead (2710), UI_ZeD_Veh_KgCaps (2715), UI_ZeD_Veh_KToReachIn (2721), UI_ZeD_Veh_LidOpen (2723), UI_ZeD_Veh_NeedsFor (2731), UI_ZeD_Veh_NoAnimalsInside (2732), UI_ZeD_Veh_NothingToDo (2740), UI_ZeD_Veh_NoVehicle (2742), UI_ZeD_Veh_PartsClosed (2748), UI_ZeD_Veh_ReadyCarcass (2754), UI_ZeD_Veh_ReadyInstall (2755), UI_ZeD_Veh_ReadyInstallItem (2756), UI_ZeD_Veh_ReadyRepair (2757), UI_ZeD_Veh_ReadyRepairWith (2758), UI_ZeD_Veh_ReadyTo (2759), UI_ZeD_Veh_ReadyWalkHer (2760)


The other 39:

UI_ZeD_Veh_ReadyWalkHim (2761), UI_ZeD_Veh_WorkingBack (2789), UI_ZeD_Veh_WorkingOn (2790), UI_ZeD_Wheel_ComingLater (2833), UI_ZeD_Wheel_WatchAlwaysOpen (2920), UI_ZeD_World_ComingSoon (2978), UI_ZeD_CMap_View (3008), UI_ZeD_Options_ZedSandbox (3030), UI_ZeD_Sbx_PutBack (3056), UI_ZeD_Dash_LampCond (3257), UI_ZeD_Dash_LampCharge (3258), UI_ZeD_Dash_LampLeft (3259), UI_ZeD_Dash_LampRight (3260), UI_ZeD_Inv_RowHelp (3474), UI_ZeD_Journal_HelpPage (3600), UI_ZeD_Journal_HelpSubTab (3601), UI_ZeD_Papers_HelpFilter (3624), UI_ZeD_MMHelp_Tutorial (3721), UI_ZeD_ObjCard_HelpBack (3839), UI_ZeD_World_WeightOf (3944), UI_ZeD_Inv_PromptMenuMarked (4530), UI_ZeD_Srv_Faction (4867), UI_ZeD_Srv_Tag (4868), UI_ZeD_Srv_Owner (4869), UI_ZeD_Srv_HelpFaction (4872), UI_ZeD_Srv_HelpSafehouse (4875), UI_ZeD_Adm_ServerMsgAsk (4900), UI_ZeD_Adm_You (4901), UI_ZeD_Adm_Kick (4904), UI_ZeD_Adm_Ban (4905), UI_ZeD_Adm_HelpStats (4909), UI_ZeD_Adm_ServerMsgWrite (4914), UI_ZeD_Adm_HelpOpenSafehouse (4919), UI_ZeD_Adm_HelpOpenFaction (4921), UI_ZeD_Adm_GameWindow (5351), UI_ZeD_Adm_HelpInv (5352), UI_ZeD_Console_HelpCopyAll (6314), UI_ZeD_Console_HelpPick (6315), UI_ZeD_Settings_BeltFull (2440)

Many come in families that read like retired designs: UI_ZeD_Veh_* (22 keys, most of them Ready* and Working*), UI_ZeD_Lock_* (10), UI_ZeD_Adm_* (10), UI_ZeD_Power_Need* (9), UI_ZeD_Fire_* (7), UI_ZeD_Mods_Rule* (6).

Six names the Lua uses that have no key and no English default (they would draw as the raw key if reached): UI_ZeD_ActionBar_Reading, UI_ZeD_Card_Needs, UI_ZeD_Watch_Day, UI_ZeD_Guide_Book, UI_ZeD_Dash_Prompt, UI_ZeD_D. The first two are the examples in Tr.lua's header comment; the last three look like cut-off prefixes in comments. UI_ZeD_Watch_Day is worth one look.

Lines saved: 149 keys in 28 files, about 4,100 JSON lines. Risk: low. i18n_guard.py is the check.

## 1.10 Pictures

5,345 files under 42/media/textures (49 MB). Most are named by a built path (the wheel icons by size and id, the dash by design and cabin), so only folders whose path never appears in the Lua, and loose files, can be called dead:

| What | Files | Size | Evidence | Ships today? |
|---|---|---|---|---|
| ZeD/dash/ (old radio and siren plates) | 10 | 1.4 MB | "textures/ZeD/dash/" appears nowhere in the Lua | Yes |
| ZeD/watch/ (old watch plates) | 9 | 76 KB | "ZeD/watch" appears nowhere | Yes |
| ZeD/test_check.png, ZeD/test_fluent.png | 2 | under 1 KB | names appear nowhere | Yes |
| ZeD/body/originals/, ZeD/body/originals-pre-s45/ | 55 | 373 KB | folder paths appear nowhere | No (stage_workshop.ps1:153) |
| 42/media/fonts/*.py, __pycache__, ZeD/icons/copy_icons.ps1, outline_icons.py | 6 | | tools, not game files | No (stage_workshop.ps1:121) |

Proposal: delete the first three rows; move the last two out of 42/ into ZeDUI/ so the mod folder holds only what ships. Risk: low.

---

# 2. Duplication

Counts are from grep over 42/media/lua. "Home" is where the one copy should live. Most homes already exist: shared/ZeD/Tokens.lua holds ZeD.logOnce and ZeD.uiSound, shared/ZeD/Tr.lua holds ZeD.tr.

| Family | Copies | Examples | Home | Lines saved | Risk |
|---|---|---|---|---|---|
| Point in a box: `local function inRect(r, x, y)` and its twins inside, hit | 42 named copies in 41 files; the same test written inline 159 times in 85 files | ZeD_CarRadio.lua:74, ZeD_Chat.lua:854, ZeD_Reader.lua:62, WindowCurtain.lua:189, JournalTab.lua:1620, FishingWall.lua:440, ZeD_TicketCards.lua:114 | ZeD.inRect in Tokens.lua | 40 now, more as inline copies are met | Low. One trap: two copies use "<=" on the far edge (ZeD_MainMenuDescEdit.lua:508, ZeD_MainMenuMail.lua:581), one pixel wider than the rest; pick "<" |
| pcall with a default: `local function safe(fn, d)` and `_safe` | 20 copies in 20 files | AdminTab.lua:53, FishingLog.lua:51, ZeD_Dashboard.lua:189, ZeD_RadioOps.lua:61 | ZeD.safe in Tokens.lua | 20 | Low. ZeD_Watch.lua:74's copy returns nil where the others return the default; keep that one or check its callers |
| Reading and writing a small text file in Zomboid/Lua | getFileReader 34 times in 27 files, getFileWriter 33 times in 28 files, 60 readLine loops; 12 private readLines / readAll / writeLines helpers | ZeD_MailStore.lua:60 and 79, ZeD_KeyboardMap.lua:124 and 135, ZeD_DeskNotes.lua:66, ZeD_ConsoleScratch.lua:133, ZeD_QuickChords.lua:86, ZeD_ModOrder.lua:61, Settings.lua:860-889, 968-972, 1012-1023, 1361-1405 | A new shared/ZeD/Store.lua: readLines(name), writeLines(name, lines), readKV(name), writeKV(name, table), exists(name), all pcall-wrapped and always closing | about 250 | Low to medium: each caller has its own small rules (max lines, a header line). Move them one file at a time |
| Is this mod on: `local function modOn()` walking getActivatedMods | 30 copies in 30 files (every ModSupport file) | ModSupport/AutoHideHotbar.lua:60, BB_WhereAmI.lua:20, BetterItemTransfer.lua:34 (identical, 9 lines each) | ZeD.modOn(id) in Tokens.lua, cached per session | about 240 | Low |
| The translation wrapper `local function tr(k, ...) return ZeD.tr(k, ...) end` | 45 files | AdminTab.lua:52, ZeD_Chat.lua:48 | `local tr = ZeD.tr` (one line, no wrapper) | 0 lines, one call less per phrase drawn | Low. If any QA script swaps ZeD.tr at run time, a captured copy would not see it; then leave the wrappers |
| The clock: `local function now()` / nowMs / ms / stamp around getTimestampMs | 63 in 58 files | Balloon.lua:105, CookingTab.lua:47, ZeD_ActionBar.lua:385 | ZeD.now in Tokens.lua | 60 | Low |
| Clamp and round | 11 clamp or clamp01, 6 round; inline math.max(a, math.min(...)) 368 times; math.floor(x + 0.5) 153 times | ZeD_Prompt.lua:62, ZeD_Keyboard.lua:43, ZeD_WindowPlaces.lua:176, ZeD_Dashboard.lua:63, ZeD_Plate.lua:88 | ZeD.clamp, ZeD.clamp01, ZeD.round in Tokens.lua | 17 | Low. Leave the inline ones |
| Text width and line height helpers: tw, textW, fh | 21 width helpers, 22 height helpers; MeasureStringX called 645 times in 111 files | | ZeD.textW(font, s) and ZeD.fontH(font) in Tokens.lua (ZeD.TM is already shared) | 40 | Low |
| Hex color parsing | 4 parsers: Tokens.lua:28 (the real one), ObjectCards.lua:682, ZeD_Belt.lua:80, ZeD_Bubbles.lua:570; 12 raw tonumber(.., 16) sites | | Export the Tokens one as ZeD.hex | 15 | Low |
| Log once | 5: ZeD.logOnce (Tokens.lua:1470), AddonOptions O.logOnce (:72), and private ones in ContainerGates.lua:61, ContainerGroups.lua:38, GridLayout.lua:99 | | ZeD.logOnce | 20 | Low |
| "Is the window open" probes | `ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ...` 23 times in 17 files; the World one 38 times in 25 files | Settings.lua:1204-1205, 1216-1217, 1277-1278 | ZeD.charWin(pn) and ZeD.worldWin(pn) in Tokens.lua, nil-safe | 30, and shorter lines | Low |
| Settings guards: `ZeD.Settings and ZeD.Settings.x and ZeD.Settings.x()` | 22 times in 18 files (13 of them the Lite probe, 1.2) | | Settings.lua loads before every reader that draws; where a guard is still wanted, ZeD.setting("x") | 20 | Low |
| The click sound: `local function sound(name)` | 21 files | ZeD_Reader.lua:63 | ZeD.uiSound already is the home; call it | 21 | Low |
| Design-pixel wrapper `local function px` | 22 files | | `local px = ZeD.T.px` where T is stable | 0 | Low |
| A cached texture loader: tex, texOf, plateTex | 20 files, each with its own cache table | ZeD_SeatPopout.lua:98-102, Atoms.lua:306-313 | ZeD.tex(path, nearest) in Tokens.lua with one cache | 80 | Low |
| Local button drawers: button, btn, drawBtn | 24 files | ZeD_Prompt.lua, ZeD_SurvivalGuide.lua, ZeD_MainMenuNotes.lua, ZeD_Studio.lua | section 3.2 | | |
| The server tables' schema loop (MIGRATE = {}, the frozen flag, the while loop) | 3 copies: server/ZeD/ZeD_ServerAdmin.lua:53 and 112-127, ZeD_ServerCommunity.lua:43 and 97, ZeD_ServerExtras.lua:54 and 111 | | One Srv.openTable(name, schema, migrate) in ZeD_ServerHelper.lua | 40 | Medium: server data; do it with the MP kit running |
| Hit-testing loops (walk a list of rects, return the one under the pointer) | In most onMouseDown handlers; 80 onMouseWheel handlers in 54 files do a version of it | | ZeD.hitIn(list, x, y), next to ZeD.inRect | not counted | Low |
| wrapText callers | 148 calls in 64 files go to the shared one; 9 files also carry a private wrap or wrapWords | ZeD_SurvivalGuideBook.lua (wrapWords), ZeD_Bubbles.lua | Fine as it is; the private ones wrap pixel fonts or rich text | 0 | |

Total for this section: about 900 lines, of which about 600 come from five families (files, modOn, the clock, inRect, textures). None of it changes what a player sees.

---

# 3. Two systems for one job

## 3.1 Pop-ups and menus

- **Questions and notes.** ZeD_Prompt (ZeD_Prompt.lua, 1,469 lines) is the one in use: 69 call sites, and Overrides/Prompts.lua turns the game's own ISModalDialog:new (19 direct uses in 13 ZeD files) into it. ZeD_Modal (Organisms.lua:2352) is the older one and has no caller. Fold: delete ZeD_Modal (1.5). Risk: low.
- **Right-click menus.** The strip (ZeD_ContextMenu.lua, 1,045 lines) and the list (ZeD_ContextList.lua, 672 lines) are a player's choice (the Context menu row), fed by one registry (ContextMenuRegistry.lua). Two views of one model: fine. ZeD_WindowMenu (299 lines) and ZeD_ListsMenu (226 lines) are small menus of their own; they could be ZeD_ContextList instances. Saves about 300 lines; risk medium (pad focus differs in each).
- **Drop-downs.** ZeD_Dropdown the class has one user (ForagingTab.lua:761); three files draw the same closed box by hand (CraftingCore.lua:1418, Stations.lua:538, ZeD_MainMenu.lua:1325), and ZeD_MainMenuOptions has its own pop-up for options. Used more: the drawn-in-place form. Fold: one ZeD.Molecules.drawSelect(panel, x, y, w, text, open) for the closed box, and let the open list be ZeD_ContextList. Saves about 250 lines (the class is 217). Risk: medium.

## 3.2 Buttons

- ZeD.Molecules.drawButton (drawn in place): 88 calls in 47 files. This is the system.
- ZeD_Button the panel class (Molecules.lua:451-525): one user, the Character window's Save button (ZeD_CharacterWindow.lua:4704).
- ZeD.Atoms.drawPillButton (AtomExtensions.lua:472): no caller.
- PlainFace's buttons (PlainFace.lua, the plain cards) and Lite's bolder buttons (Molecules.lua:121-148, 368): a second look on purpose.
- 24 files have a private button() or btn() that wraps drawButton with a hit rect and a focus element.

Fold: move the one ZeD_Button user to drawButton and delete the class (75 lines); delete drawPillButton; give Molecules one drawButtonHit(panel, list, id, ...) that returns the rect and registers the focus element, and let the 24 private wrappers call it (about 200 lines). Risk: low for the first two, medium for the wrappers (each has small differences in padding).

## 3.3 Scrolling

- ZeD.Molecules.ScrollbarState: 40 uses outside the library. The system.
- ZeD_ScrollList and ZeD_ScrollPanel (Organisms.lua): never created. ZeD.Atoms.drawScrollThumb: no caller.
- Hand-rolled: 52 places in 24 files clamp their own scrollY, and 80 onMouseWheel handlers in 54 files each decide what the wheel scrolls. CookingTab.lua:128 even builds a stand-in panel (s.shim) so the wheel reaches its columns.

Fold: delete the dead ones (1.5). For the hand-rolled ones, one ZeD.Molecules.wheel(state, del, contentH, viewH) that clamps and returns whether it moved. Saves about 150 lines. Risk: low; per-file, no behavior change intended.

## 3.4 Where settings are kept

Four stores:

1. ModOptions.ini through the game's PZAPI: 64 options (section 5). The main one.
2. 40 small text files in Zomboid/Lua (ZeD_chords.txt, ZeD_window_places.txt, ZeD_custom_additions.txt, ZeD_setup.txt, ZeD_hints.txt, ZeD_tutorial.txt, ZeD_setup_seen.txt, ZeD_guidebubble.txt, ZeD_step_aside.txt, ZeD_safe_trip.txt and so on), each with its own reader and writer (section 2).
3. 27 keys on the character (modData): ZeD_WinState, ZeD_Theme, ZeD_Journal, ZeD_Lists, ZeD_Pins and so on. Right for things that belong to a character.
4. The sandbox options file, for the server-side rules.

What is doubled:
- The theme lives in the options and is copied to the character as ZeD_Theme (Settings.lua:117-128), "never read back over them". Only players 2 to 4 in split view read it (PlayerTheme.lua, 235 lines), and split view is on hold behind a file flag (Atoms.lua:1856-1866, ZeD_splitview_on.txt; 15 mentions of splitWindows in 9 files, plus ZeD_SplitSpeed.lua, 198 lines). Decide for 1.0: ship split view, or leave the flag and accept about 450 lines of parked code. Do not delete; it is a planned feature.
- The glyph and input-lock picks are copied to the character as ZeD_Gamepad and nothing reads them (1.7). Delete.
- Per-window accents live in three places at once: the options (charAccent, worldAccent), the pending fields ZeD._pendingCharAccent / _pendingWorldAccent, and the character's ZeD_WinState[...].accentKey, kept in step by setWindowAccent, syncWindowAccent and applyWindowAccentsFromOptions (Settings.lua:1139-1160, 1197-1236, 1255-1268; about 100 lines). The comment says the options win. Then the copy in ZeD_WinState is not needed: read the option when the window opens. Saves about 60 lines. Risk: medium (window restore order).
- Seven one-flag files that only record "this happened once" (ZeD_setup_seen, ZeD_tutorial, ZeD_guidebubble, ZeD_presetRepair, ZeD_console_off, ZeD_splitview_on, ZeD_safe_trip): one ZeD_flags.txt through the shared store. Saves 6 files in the player's folder and about 60 lines. Risk: low, but it needs a read of the old files for one release, which is a new shim. Only worth it if Store.lua (section 2) is built.

## 3.5 How windows remember their place

- Per character: modData ZeD_WinState (21 mentions in 5 files): where the Character and World windows open, their tab, drawer and accent. Plus ZeD_WinPinned for the halves.
- Per computer: ZeD_window_places.txt (ZeD_WindowPlaces.lua): the window menu's "Save position" and "Go to saved position", used only when asked.
- Their own files: the chat window (ZeD_chatwin.txt), the desk's sticky note (ZeD_desk_sticky_place.txt).
- The game's own layout file is used once.

Used more: ZeD_WinState. The header of ZeD_WindowPlaces.lua explains the split well (a place is about the screen, a layout about the character), so this is two jobs, not one. What can fold: the chat window and the sticky note can keep their place through ZeD_WindowPlaces (it already takes any window by id). Saves two files and about 50 lines. Risk: low.

## 3.6 Balloon, GuideBubble, tooltips

This one is already mostly one system:
- Balloon.lua (796 lines) is the single hover box; 16 files draw through it, including RichTip (the game's requirement lists), ZeD_InvTip (the loot card), the hint strip and the tutorial.
- ZeD_GuideBubble.lua (170 lines) is not a second drawer. It is a timer that posts one line through Messages.
- ZeD_Bubbles.lua (899 lines) is the over-the-head family (speech, thought, the game's notes); a different job.
- Overrides/Tooltip.lua (377 lines) restyles the game's own item tooltip, which stays the game's (Alt shows it).

Leftovers to delete: the ZeD_Tooltip class (Atoms.lua:1105-1160), ZeD.Atoms.hoverBoxPlace (Atoms.lua:1196, "older callers", none left), the stub at ContainerControls.lua:1077, the opts.now spelling at Atoms.lua:1169. About 90 lines. Risk: low.

## 3.7 English text in two places

Every phrase is in EN/UI.json. 401 of them are also written as English defaults inside the Lua (ZeD.trDefaults tables in about 20 files, for example ZeD_Dashboard.lua:1534-1548), "so a missing or broken translation file never shows raw keys". The two copies can drift (change the JSON, forget the Lua). Used more: UI.json (6,951 keys against 401).

Fold: the mod always ships its own EN/UI.json, so the defaults protect only against a broken file. Either drop the tables (a few hundred lines) or generate them from the JSON at release so they cannot drift. Risk: low for generating, medium for dropping (a key missing from a language falls back to the game's EN, which is the same file).

## 3.8 The Lua console

ZeD_DebugConsole.lua and the five ZeD_Console*.lua files (5,630 lines) also ship as the separate mod Lua Console 93, generated from these files by ZeDUI/tools/products/build_luaconsole93.py. One source, two products: fine. Nothing to fold.

---

# 4. Oversized units

## 4.1 The 15 largest files

| # | File | Lines | Note |
|---|---|---|---|
| 1 | ZeD_CharacterWindow.lua | 7,654 | Split. One function, toggle (4160), is 3,153 lines and holds 51 nested functions (15 on content, 9 on drawer, 7 on containerStrip, 4 for the identity model). Move each family to its own file as module functions that take the window: CharDrawer.lua, CharContent.lua, CharStrip.lua, CharFocus.lua (the _build*Focusables) |
| 2 | PhysPx.lua | 7,558 | Fine. Generated data (export_phys.py), no functions |
| 3 | ZeD_WorldWindow.lua | 6,514 | Split the same way as 1. toggle (3575) is 2,562 lines. The two windows mirror each other, so the split files can be shared in part (the drawer and the container strip are near twins: drawContainerStrip at Char:3660, 364 lines; drawWorldContainerStrip at World:3032, 431 lines) |
| 4 | Molecules.lua | 5,269 | Split by kind: text fields (675-965), scroll and drag state, dropdown, the card rows. Delete the dead ones first (1.5, 1.6: about 370 lines) |
| 5 | AnimalsTab.lua | 4,238 | Split by its own state machine: ranch and butcher, each with overview, zone and animal views. 131 functions |
| 6 | CraftingCore.lua | 3,860 | Split: the recipe list (renderRecipeList, 280 lines), the craft card (renderCraftCard, 317), focus (buildFocusables, 343) |
| 7 | InventoryRenderer.lua | 3,799 | renderItemList (714 lines) is the piece to break up: list rows and grid tiles are separate branches of it |
| 8 | Input/FocusManager.lua | 3,315 | Move _handleSpatialNav (410 lines, 177 locals) into Input/SpatialNav.lua, which exists |
| 9 | ZeD_MainMenu.lua | 3,192 | Already split into 25 ZeD_MainMenu*.lua files; this is the room and the menu bar. Fine for now |
| 10 | ZeD_TicketCards.lua | 2,773 | It is also "the card engine" for Mail, Claims, Community and Log cards (its header). Move the engine to its own file |
| 11 | ZeD_Belt.lua | 2,744 | Split: layout, slots, the ammo tab, the PvP and chat markers |
| 12 | ZeD_DebugConsole.lua | 2,715 | Debug only, and its own product. Fine |
| 13 | Organisms.lua | 2,641 | Drops to 1,836 after 1.5. What is left is mostly ZeD_Window |
| 14 | ZeD_Dashboard.lua | 2,597 | Drops to about 1,980 after 1.3. The odometer (890-1190) is a module of its own |
| 15 | ZeD_MainMenuMods.lua | 2,582 | Already has four companion files. drawProfiles (193 lines, 143 locals) should move to one |

## 4.2 The 30 longest functions

Locals are the declared count the game's compiler uses (limit 200). A parser artifact (a data table in ModSupport/EvolvingTraitsWorld.lua read as nested functions) is left out.

| # | Function | File:line | Lines | Locals | Note |
|---|---|---|---|---|---|
| 1 | ZeD_CharacterWindow.toggle | ZeD_CharacterWindow.lua:4160 | 3,153 | 51 | Split (4.1 row 1) |
| 2 | ZeD_WorldWindow.toggle | ZeD_WorldWindow.lua:3575 | 2,562 | 54 | Split (4.1 row 3) |
| 3 | renderItemList | InventoryRenderer.lua:2353 | 714 | 139 | Split list and grid. It has hit 200 before (Oct 19). Three dead locals inside (1.6) |
| 4 | ZeD.SkillsTab.render | SkillsTab.lua:1093 | 469 | 143 | Split: header, the skill rows, the card |
| 5 | drawWorldContainerStrip | ZeD_WorldWindow.lua:3032 | 431 | 172 | NEAR THE LIMIT. Twin of row 11; share one strip drawer |
| 6 | toggleTestInventory | TestInventory.lua:39 | 422 | 13 | Dev file, not shipped. Fine |
| 7 | ZeD.EquipmentTab.render | EquipmentTab.lua:1348 | 418 | 128 | Split: the doll, the list, loadouts |
| 8 | _handleSpatialNav | Input/FocusManager.lua:1882 | 410 | 177 | NEAR THE LIMIT. Split per direction or per window kind, into SpatialNav.lua |
| 9 | drawer._onPrerender | ZeD_CharacterWindow.lua:4938 | 406 | 87 | Goes with the toggle split |
| 10 | renderJournal | JournalTab.lua:893 | 380 | 136 | One function per page |
| 11 | drawContainerStrip | ZeD_CharacterWindow.lua:3660 | 364 | 128 | Twin of row 5 |
| 12 | applyTooltipOverrides | Overrides/Tooltip.lua:22 | 353 | 21 | A wrapper around a set of hooks. Fine |
| 13 | _buildEquipmentFocusables | ZeD_CharacterWindow.lua:2141 | 351 | 105 | Belongs to EquipmentTab |
| 14 | CC.buildFocusables | CraftingCore.lua:3518 | 343 | 38 | Fine, a long list of cases |
| 15 | CC.renderCraftCard | CraftingCore.lua:2519 | 317 | 106 | Split by card section |
| 16 | _buildAnimalsFocusables | ZeD_WorldWindow.lua:815 | 297 | 77 | Belongs to AnimalsTab |
| 17 | renderClothingBody | ItemCardOrganism.lua:799 | 290 | 113 | Split by zone |
| 18 | drawer._onPrerender | ZeD_WorldWindow.lua:4208 | 287 | 70 | Goes with the toggle split |
| 19 | CC.renderRecipeList | CraftingCore.lua:1905 | 280 | 109 | Row drawing out to its own function |
| 20 | ZeD.HealthTab.render | HealthTab.lua:1656 | 273 | 72 | Fine |
| 21 | content._focusRefresh | ZeD_WorldWindow.lua:5232 | 270 | 98 | One builder per tab, as the Character window has |
| 22 | drawer.onMouseDown | ZeD_CharacterWindow.lua:5443 | 260 | 64 | Goes with the toggle split |
| 23 | B.paginate | ZeD_SurvivalGuideBook.lua:555 | 254 | 134 | Fine for now; book layout is one job |
| 24 | content.onMouseDown | ZeD_CharacterWindow.lua:6847 | 243 | 79 | Goes with the toggle split |
| 25 | content.onMouseDown | ZeD_WorldWindow.lua:5663 | 235 | 81 | Same |
| 26 | setUpAdditions | Settings.lua:812 | 231 | 46 | Drops to about 170 after 1.1 and do-first 7 |
| 27 | CC.render | CraftingCore.lua:2845 | 226 | 53 | Fine |
| 28 | buildWorldContainers | ZeD_WorldWindow.lua:2773 | 224 | 66 | Fine |
| 29 | ZeD_BeltHUD:_prerender | ZeD_Belt.lua:2048 | 217 | 76 | Fine |
| 30 | ZeD.AnimalsTab.onClick | AnimalsTab.lua:3905 | 215 | 66 | A table of handlers by id would halve it |

Overall: 3 functions over 500 lines, 26 over 300, 55 over 200, 235 over 100.

## 4.3 Close to the 200-local limit

The game's compiler in debug mode fails a file at 200 declared locals in one function, and the file-level code counts as one function.

| Where | Declared locals | Note |
|---|---|---|
| Input/FocusManager.lua:1882 _handleSpatialNav | 177 | 23 left |
| Settings.lua, the file level | 177 | 23 left. Every new option adds one or two. Deleting the eight retired options gives back 8; wrapping each option family in a function (as setUpAdditions is) gives back most of the rest |
| ZeD_MainMenuOptionGroups.lua:301 G.build | 172 | 179 lines with many loops; each loop costs its variables plus 3 |
| ZeD_WorldWindow.lua:3032 drawWorldContainerStrip | 172 | |
| AnimalsTab.lua, the file level | 162 | |
| Molecules.lua, the file level | 159 | |
| ZeD_Dashboard.lua, the file level | 151 | About 30 fewer after 1.3 |
| Balloon.lua:273 B._layout; SkillsTab.lua:1093 render; ZeD_MainMenuMods.lua:2137 drawProfiles | 143 each | |
| InventoryRenderer.lua:2353 renderItemList | 139 | 190 if its nested helpers are counted with it |

A cheap guard: run this count in the release check and fail at 185.

---

# 5. Settings the player sees

Settings.lua registers 64 options (every opts:addComboBox, and the onSwitch helper). ZeD setup shows 56 of them in six groups, plus 12 chord rows (not options) and 6 copies of game settings. The game's own Mods page shows all 64.

Two kinds of merge are meant below. **Show as one**: both options stay stored as they are, ZeD setup draws one control that sets both (a new row type in G.ZED_GROUPS). No saved value changes meaning, no migration, and that is the kind proposed for 1.0. **Drop**: the option object is deleted.

## Look (11 shown)

| Option | Verdict | Why |
|---|---|---|
| lookStyle (Lite or Full) | Keep | The one Style switch |
| baseTheme | Keep | |
| accentColor | Keep | |
| statusColors | Keep | Color-blind access |
| mapLight | Keep | New Nov 19 |
| textSize | Keep | |
| seeThrough | Keep | |
| solidInUse | Show as one with seeThrough | It only matters when see-through is under 100; draw it as a checkbox on the same row. Rows: 2 to 1 |
| healthBlink | Keep | Access |
| gridTint | Keep | New Nov 16 |
| uiScale | Keep | |

## Additions (18 shown; hidden in Lite)

| Option | Verdict | Why |
|---|---|---|
| additionsPreset | Keep | |
| ammoBox | Keep | |
| readMarks, readNext, dimRead | Show as one: Off, Marks, Marks and dim read | One feature in three parts (what is read, what to read next, read ones dimmed); every preset sets the three together. Rows: 3 to 1 |
| dashLamps | Keep | |
| moodleNotices, haloBubble | Show as one: Overhead notes (None, Game notes, Game notes and moodles) | Both are notices in the ZeD bubble; every preset sets them together. Rows: 2 to 1 |
| messagesCatch, messagesToast | Show as one: Off, Keep in Messages, Keep and toast | The toast announces what Messages caught; every preset sets them together. Rows: 2 to 1 |
| hintStrip | Keep | |
| putBack | Keep | |
| sandboxInGame | Keep | |
| hiddenFacts, autoLearn | Show as one: Find first, Always | In all three presets Recipes skills teach is On exactly when Hidden facts is Always. Rows: 2 to 1 |
| loadouts, restock | Show as one: Off, Hardcore, Casual, Accessible | Restock already dims while Loadouts is off. Rows: 2 to 1 |
| appliances | Keep | Off in every preset on purpose |

## Windows (7 shown)

| Option | Verdict | Why |
|---|---|---|
| inventoryView | Keep | The default for every container |
| contextStyle | Keep | |
| equipView | Hide the row, keep the stored value | The toggle in the Equipped heading already sets it (Settings.lua:237-244). One way in is enough |
| charAccent, worldAccent | Hide the rows, keep the stored values | Each window box's menu sets its accent (ZeD_WindowMenu.lua). See 3.4 |
| uiSounds | Keep | |
| hiddenActions | Keep | |

## HUD (2 shown)

| Option | Verdict | Why |
|---|---|---|
| moodlePlace | Keep | |
| watchPlace | Keep, dim in Lite | Lite forces the corner (ZeD_Watch.lua:315-317), so a pick does nothing there; check that the row dims and says why |

## Controls (8 shown, plus 12 chord rows)

| Option | Verdict | Why |
|---|---|---|
| focusStyle | Keep | |
| glyphDisplay | Keep | |
| inputModeLock | Keep | |
| wheelOpen, wheelCommit, wheelToggle | Show as one: Wheel style with five choices (Tap and flick, Hold and flick, Tap and click, Hold and click, Toggle) | Toggle already overrides the other two and dims them. Rows: 3 to 1 |
| wheelDeadZone | Keep | |
| runSneak | Keep | |
| The 12 chords | Keep | Not options; their own store |

## Trouble (10 shown)

| Option | Verdict | Why |
|---|---|---|
| safeMode | Keep | |
| screenWindows, screenBelt, screenWatch, screenDashboard, screenMoodles, screenWheels, screenCharInfo | Keep (7) | Players asked for them. They could sit behind one "Hand a screen back" fold so the group reads as two rows until opened |
| screenConsole | Show in debug mode only | The console exists only with -debug |
| testLanguage | Show in debug mode only | A translator's and QA's tool |

## Retired (8, never shown in ZeD setup, still on the game's Mods page)

actionBar, beltStyle, devicesStyle, watchStyle, dashStyle, guideStyle, modsStyle, identityStyle: **Drop** (1.1).

## Count

| | Registered | Rows shown in ZeD setup |
|---|---|---|
| Today | 64 | 56 |
| After dropping the retired eight | 56 | 56 |
| After the show-as-one merges (seven merges, 16 rows become 7) and the five hidden rows (equipView, the two accents, screenConsole, testLanguage) | 56 | 42 |
| If the merges are later made real (one option each) | 47 | 42 |

Either way it is a quarter fewer rows. Lines: about 80 added for the combined row types, about 110 removed (1.1). Risk: low for hiding rows, medium for the combined controls (new drawing in ZeD_MainMenuOptions, and the controller path through each).

---

# 6. Shims and compatibility layers

| What | Where | Served | Go at 1.0? |
|---|---|---|---|
| The eight hidden options and the helpers that redirect them | Settings.lua:280-288, 618-694 | Beta 21 (Nov 19), for saves from beta 20 and before | Yes (1.1). The game keeps the old lines by itself |
| One-time repair of the Identity row for Vanilla Access players; writes ZeD_presetRepair.txt | Settings.lua:955-992, 997 | Beta 6 (Nov 6) | Yes. It needed one launch of any build since. The file it leaves in the player's folder is harmless |
| "A player who had ZeD before the additions' switches": reads ModOptions.ini at file load and turns additions on for them (WAS_ON) | Settings.lua:1007-1029 | The test builds before Oct 30 (t12 and earlier) | Yes. Only a tester who has not saved options since October would notice. 23 lines and one file read at every load |
| The same block's second half: Vanilla Access players get the style rows set to Simple | Settings.lua:1030-1039 | Betas 6 and 7 | Yes, with 1.1 (four of its six ids are retired; keep nothing) |
| savedHas, used only by the repair | Settings.lua:963, 1024 | Beta 6 | Yes, with the repair |
| The Custom additions file | Settings.lua:815, 860-889 | Not a shim: live | Keep |
| The character's theme copy clears "own" | Settings.lua:125-127 | Split view (beta 13, on hold) | Keep while split view is parked |
| The 0.5x UI scale step kept in the list but not offered | Settings.lua:201-212, shared/ZeD/Scale.lua:172-176 | "not offered in the beta" | Decide at 1.0: offer it or leave the rule and fix the comment. The item cannot be removed (it is first in a list saved by position) |
| Old kill tables fixed once (KILLS_VERSION) | KillTracker.lua:149-219, 409; JournalTab.lua:689; Overrides/PostDeath.lua:147 | Beta 7 or 8 (Nov 7) | Keep one more release. It fixes data inside a character's save, and saves live long |
| Old map marks moved into the game's store once per character (ZeD_MapNotesMoved) | MapNotes.lua:288-359, MapsTab.lua:375 | The test builds before Oct 20 | Yes, with care: a character from before Oct 20 that was never loaded since would lose its old marks. 75 lines |
| An older save's single window pin read as "both halves pinned", and still written | WindowHalves.lua:27-30, 71, 139 | Beta 8 or 9 (Nov 8) | Reading: keep one more release (character data). Writing the old key "for anything that still reads it": go now, nothing reads it |
| The floor's old filter let go once per window | InventoryFilter.lua:87 | Beta 11 or 12 (Nov 12) | Yes |
| ZeD_Lists.migrate | ZeD_Lists.lua:85-115 | Not a beta shim: it repairs a damaged list store | Keep |
| ZeD_ModFolders decodeV1 | ZeD_ModFolders.lua:135-150 | Not ZeD's: it reads another mod's (Mod Folders) older file | Keep |
| The server tables' MIGRATE steps | server/ZeD/ZeD_ServerAdmin.lua:53, ZeD_ServerCommunity.lua:43, ZeD_ServerExtras.lua:54 | Empty today: the frame for later | Keep, fold the three loops into one (section 2) |
| Old argument and field names kept "for older callers" | Atoms.lua:1169 (opts.now), 1194-1209 (hoverBoxPlace), 1753 (unused glyph); Molecules.lua:2379-2381 (two unused parameters); JournalTab.lua:867; ZeD_MainMenuModsOrder.lua:217; ReadMarks.lua:264 (DOT_W); ContainerControls.lua:825 (HINT_MS), 1077; ZeD_FocusPaint.lua:289 (FP.paint) | Internal renames during the betas | Yes. All callers are in this repo; grep finds none left for hoverBoxPlace, DOT_W, FP.paint and HINT_MS |
| The translation key UI_ZeD_Settings_ActionBarVerbose still named for the row's old word | Settings.lua:283, 286, 679 | Beta-era rename | Goes with 1.1 |
| The F6 test window | TestInventory.lua | Development | Already left out of the Workshop build |
| Add-on contract versions (GridLayout GL.VERSION = 2, the keyboard map's VERSION line) | GridLayout.lua:86, ZeD_KeyboardMap.lua:159 | Not shims: live contracts | Keep |

Net at 1.0: about 190 lines of shim code can go (beyond 1.1), and Settings.lua stops reading ModOptions.ini by hand at every file load.

---

# 7. ZeDUI/tools/qa

The folder holds 852 Lua scripts, 605 manifests (.txt), 148 runners (.ps1) and 226 untracked run leftovers (.err, .out, .log, .pid, .start).

## 7.1 Scripts that still set the retired switches (their Simple legs now test Full)

Already marked and not listed again: zedqa_all_simple.lua, zedqa_b16.lua, zedqa_b19_light_popups.lua, zedqa_aiming_clip.lua. Also already carrying a note: forms_phrase_sim.lua, zedqa_roadworthy.lua.

Unmarked, 39 files. Setting the old option now changes nothing, so any check or picture that follows shows Full:

Checks:
- zedqa_simple_belt.lua: beltStyle. The whole script is the Simple belt; it now measures the strap belt.
- zedqa_simple_watch.lua: watchStyle. Same, for the watch.
- zedqa_plain_cards.lua: devicesStyle. The plain device cards.
- zedqa_devices_form.lua: devicesStyle.
- zedqa_dash_form.lua: dashStyle. The plain strip, which is gone.
- zedqa_dash_odo.lua: dashStyle. Its strip leg.
- zedqa_b8_dash.lua: dashStyle, and calls D.plainSpeed (dead code, 1.3).
- zedqa_b8_forms.lua: all eight.
- zedqa_b8_hidden.lua: guideStyle.
- zedqa_book83.lua, zedqa_book83_lang.lua: guideStyle (book against window).
- zedqa_mods_read.lua, zedqa_mods_lang.lua: modsStyle (the Simple mods view).
- zedqa_cov_b9to11.lua: beltStyle.
- zedqa_repair_check.lua: identityStyle (the beta 6 repair; goes with it).
- zedqa_framed_ring.lua, perf_capture.lua, test_actionbar.py: actionBar.
- hidden_facts_sim.lua: six of the eight, as preset rows.
- alt_tab_gaps_sim.lua, belt_mods_sim.lua: name the ids only.

Sims that replace the helper itself, so they still drive code the game can no longer reach:
- dash_odo_sim.lua:153 and vskdash_sim.lua:130 set dashSimple to their own function and exercise the plain strip (vskdash_sim.lua:609 reads D._plainPlan). They pass while testing dead code.
- hud_perf_sim.lua:539 (watchSimple), face_popouts_sim.lua:116 and guide_lang_sim.lua:28, 40 (devicesSimple, guideSimple): still valid as Lite legs; rename the stub to lite.
- zedqa_cov_vehicles.lua:370 and zedqa_rtv.lua:364 pin devicesSimple in the live game: still valid, same rename.

Gallery and showcase scripts (pictures, not checks; they set the action bar or a form before a shot):
- gallery_v1_c1_house.lua, gallery_v1_c1_street.lua (actionBar), gallery_v1_c2_garage.lua (dashStyle), gallery_v1_c3_a.lua (guideStyle), gallery_v1_c3_b.lua (belt, dash, devices, watch): the current 1.0 gallery set. A retake of the Simple pictures would come out Full; they need lookStyle.
- showcase_s2.lua (touched Nov 19): belt, dash, devices, watch.
- gallery_b19_a.lua, gallery_b19_b.lua, gallery_beta_new.lua, gallery_beta3_breaks.lua, gallery_nov1_lot.lua, gallery_story_shots.lua, gallery_story_stage.lua, gallery_v3_zed.lua, gallery_v5_five.lua, zedqa_gallery_shots.lua, zedqa_gallery_staged.lua: old galleries; archive (7.2).

Suggested fix for the ones that stay: one helper in rt_kit.lua, Q.style("lite" or "full"), and a line in the release check that fails on any script naming the eight ids.

## 7.2 Superseded by the release test (release_test.txt, rt_*.lua)

Every script is named by some manifest, so "unused" cannot be read from the files; these are judged by family. The folder already has archive/ and retired/.

- The per-beta runs: the manifests and runners b3_, b3a_, b6a_, b7f_, b8_, b8a_, b8n_ to b8n5_, b9_, b9a_, b10_, b10chk_, b10r_, b11_, b11n_, b11r_, b12_, b13b1_, b15_, b16_, b17_, b19_ (about 280 files), and the 67 zedqa_b<N>*.lua scripts they ran. Each proved one beta. Archive, but for any a live manifest still lists.
- The 72 batch_*.ps1 runners (batch_b6_stage, batch_stage_true and so on): staging for betas 5 to 10. Archive all but any that zedqa_run.ps1 still calls.
- The old galleries: gallery_b10 (31 files), gallery_b11 (67), gallery_b13, gallery_b19 (14), gallery_beta, beta2, beta3, gallery_nov1 (11), gallery_t13, t14 (16), gallery_v3, v4, v5, gallery_cinema (15), gallery_story (7), gallery_farm, gallery_stadium: about 200 files. The live gallery is gallery_v1_* (56 files). Archive the rest.
- The form scripts the Style switch made moot: zedqa_simple_belt, zedqa_simple_watch, zedqa_plain_cards, zedqa_devices_form, zedqa_dash_form, zedqa_all_simple, zedqa_b8_forms; rt_lite.lua covers Lite now.
- dash_odo_sim.lua's and vskdash_sim.lua's plain-strip legs, and zedqa_b8_dash.lua: go with 1.3.
- zedqa_repair_check.lua: goes with the beta 6 repair.
- Four folders with names like "720 regression.txt t15pre_720N" (October test-build baselines, by their names): look, then archive.
- 226 run leftovers (*.err, *.out, *.log, *.pid, *.start): untracked; delete.
- test_actionbar.py: written for the retired action bar switch (Oct 19). Retire or point it at lookStyle.

Keep: release_test.txt and the rt_ set (21 files), zedqa_run.ps1 and zedqa_prelude.lua, the MP kit (mp_*, 128 files), the compat runs (compat_*, 58), the 156 *_sim.lua (they run without the game), perf_*, welcome_run.ps1 with zedqa_menu_welcome.lua and zedqa_menu_lite.lua, zedqa_menu_mods_run.ps1, zedqa_minsidebar.lua and minsidebar_manifest.txt (the feature map leans on those).

Result: about 630 tracked files can move to archive/ and 226 leftovers can be deleted, out of 1,969 entries, which makes the live set readable. Risk: low; a move, not a delete.

---

# Totals

| Section | Lua lines | Other |
|---|---|---|
| 1. Dead code | about 3,800 | 149 phrases now and 67 after, in 28 files; 21 pictures that ship today, 55 pictures and 6 tool files that do not |
| 2. Duplication | about 900 | |
| 3. Two systems (beyond what section 1 deletes) | about 1,100 if all are taken; about 400 for the low-risk ones | |
| 6. Shims (beyond 1.1) | about 190 | |
| 7. QA | | about 630 files to archive, 226 leftovers to delete, 39 scripts to fix or retire |

Not done in this audit: no game run, so "looks dead" for pictures was not confirmed on screen; the 33 glued prefixes were checked at their call sites for the short ones only; functions reached only through a name built at run time would not show as live in the name search (the six ZeD_Prompt stubs are the known case).
