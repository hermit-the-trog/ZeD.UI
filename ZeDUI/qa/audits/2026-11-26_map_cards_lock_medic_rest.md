# Object cards (lock, medic, laundry, placement, track, trade, preview) and their host: map for the gamut sweep (QA, Nov 26 2026)

A read-only map of seven of ZeD's object cards and the card host they share, set against the game's own windows and actions they stand in for (B42: ISDigitalCode and the padlock actions, ISHealthPanel and ISMedicalCheckAction, the loot window's laundry handlers and toggle actions, ISExtendedPlacementUI, ISAnimalTracksUI, ISTradingUI and the Build and Craft panels' own readings). Written before the sweep scripts. Line refs are as read on Nov 26. Nothing was run.

**Scope note: the lock card is a padlock card only.** ObjectCardLock.lua resolves only an IsoThumpable (LK:92), the built crates, lockers, counters and bars that take a padlock. Doors, windows, door locks and keys, lockpicking and barricades have no ZeD card and no ZeD hook: ISLockDoor, ISBarricadeAction, onLockDoor and the barricade menus appear nowhere in ZeD's Lua (grep, Nov 26). They stay the game's own world menu and actions. The only ZeD surface that names a barricade is the recipe preview (no strength line for it, PV:138-139). So "a lock left open or a barricade lost" can only come through the padlock card on this map.

**Every card is a guest of the World window.** The card sits in the World window's item drawer overlay (ZeD_ObjectCard, made at WW:4518-4522), over the open tab or the Loot view. Its focus zone is worldItemCard (OC:920, WW:6608-6621).

Short names: OC ObjectCards.lua (the host), LK ObjectCardLock.lua, PD Overrides/Padlocks.lua, MD ObjectCardMedic.lua, TM Overrides/TradeMedic.lua, HT HealthTab.lua, LA ObjectCardLaundry.lua, CT ContainerControls.lua, PL ObjectCardPlacement.lua, FU Overrides/Furniture.lua, TK ObjectCardTrack.lua, AN Overrides/Animals.lua, TC ObjectCardTrade.lua, ZT ZeD_Trade.lua, PV ObjectCardPreview.lua, WW ZeD_WorldWindow.lua, FM Input/FocusManager.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua unless noted): WOCM client/ISUI/ISWorldObjectContextMenu.lua, DC client/ISUI/ISDigitalCode.lua, PBC shared/TimedActions/ISPadlockByCodeAction.lua, PA shared/TimedActions/ISPadlockAction.lua, ISHP client/XpSystem/ISUI/ISHealthPanel.lua, MCA client/TimedActions/ISMedicalCheckAction.lua, CWT / CDT / CWDT / CWDM client/ISUI/LootWindow/Handlers/ClothingWasherToggle.lua, ClothingDryerToggle.lua, CombinationWasherDryerToggle.lua, CombinationWasherDryerSetMode.lua, TCW shared/TimedActions/ISToggleClothingWasher.lua (ISToggleClothingDryer, ISToggleComboWasherDryer, ISSetComboWasherDryerMode beside it), EPU client/ISUI/ISExtendedPlacementUI.lua, EPA client/TimedActions/ISExtendedPlacementAction.lua, ATU client/ISUI/Animal/ISAnimalTracksUI.lua, IATA client/TimedActions/Animal/ISInspectAnimalTrackAction.lua, ITU client/ISUI/ISTradingUI.lua, BIE server/BuildingObjects/ISBuildIsoEntity.lua.
FEATURE_MAP (ZeDUI/tools/qa/FEATURE_MAP.md) lines 353 and 357 cite old host lines: openObjectCard WW:6167 is now WW:6576, closeObjectCard WW:~6191 is WW:6602, close OC:925 is OC:932, _pointer OC:1523 is OC:1575, buildFocusables OC:1625 is OC:1677, press OC:931 is OC:938, setEntry OC:879 is OC:886. Line 363's LD.open 441 is LA:659, rowSpec 451 is LA:669. Line 365 says the wheels turn with Up / Down; on the pad A grabs them first (FM:1003-1008). Lines 370 and 371 say "not here" and "the compat run"; zedqa_cov_objcards covers both cards (with a stand-in track).

---

## OC. The host (ObjectCards.lua, 1722 lines)

### OC 1. What it does

**Getting there:**
- OC.open(player, kind, obj) (OC:152-159): the kind's resolve, then ZeD_WorldWindow.openObjectCard (WW:6576-6598), which opens the World window when shut, leaves multi-column Loot, clears the item selection, puts the card over the tab (or opens the drawer on Loot) and asks for the pad's focus (_grabFocus).
- OC.openNear (OC:183-194): past the kind's leash less half a tile, or on another floor, luautils.walkAdj and a one-tick ZeDOpenCardAction (OC:164-181) that opens the card at the end of the walk.
- A card opened over another replaces it at once (WW:6592-6595); only the old kind's onClose runs (OC:889-892).

**The frame (prerender OC:1374-1546):**
- Header, the shared strip (drawHeader OC:1079-1173): the close key oc:back (OC:1088-1090), the kind's icon or pixel icon, the name, the state tag, then on the right the browse arrows with "n / m" (OC:1134-1152) and the pop-out key oc:pop for a machine face (OC:1121-1132). headFit (OC:1050-1074) drops the pop-out key, then the count, then the arrows before the name falls under three letters; a dropped button has no zone and no pad stop. On a narrow card the tag takes a row of its own (OC:1158-1162, 1177-1188).
- The verb row (drawVerbs OC:1205-1281): the primary verb first, the ones that ask last (inOrder OC:1191-1201); a label too wide is cut with "..." (OC:1240-1243). Hidden actions (ZeD.Disclose): folded (one "With ... you could ..." row, OC:1260-1277), all (grayed with a NEEDS line each, OC:1254-1258) or hide.
- The body: one scrolled unit in a stencil (OC:1445-1477); the kind's body draws at the card's width less a 10-unit pad each side. Focus follows the stop (OC:1480-1508).
- The band at the foot, in this order: a question (OC:1512-1534), else the kind's own foot (trade: OC:1344-1372, 1426-1434), else the kind's state line (OC:1435-1444). A half kind wraps a long line into a strip above the band (footLines OC:1289-1313).
- No progress band of its own: a kind draws one in its body if it wants one (the lock does, LK:548-600; none of the other six do).

**Upkeep (OC.tick OC:252-306, run from prerender OC:1381):**
- valid() every frame; a kind marked keepOnLoss steps to the next one (farm only).
- In a vehicle every kind closes unless vehicleOk (medic, trade); a dead character closes it (OC:272).
- The leash (OC.LEASH 6, OC:57; a kind's own leash: lock 4, placement 3): past leash + 0.5 tiles from the square's center, or another floor, the card closes (OC:285-288). The hold: from the frame the action queue goes from empty to busy until it is empty again, the leash is off (OC:279-284).
- refresh() every 15 sixtieths (250 ms) or at once after a verb (OC:290-295, 958); nearby() every second for the browse list (OC:296-304).

**Verbs (press OC:938-960):** confirm opens a question with the focus on Cancel (OC:943-948); jump moves view and focus into the body (OC:949-954); run runs it and refreshes 50 ms later (OC:955-959). The question's Yes runs the stored run on the target as it is at the press (OC:1525-1533).

**Closing:** the close key, B, a verb that closes (OC:932-935, closeObjectCard WW:6602-6631, which forces a pinned card out too); a tab switch, a second column, a tab click or an item card (WW:2465, 2533, 5067, 5177-5180, through dropObjectCard WW:105-124, which keeps a pinned card); tick returning false. Closing the World window (_closeWorldWindow WW:3908-3927) drops the window and the card with it, without dropObjectCard or setEntry(nil).

**The half card and the full card:** a full kind's drawer is always 480 (objectDrawerW WW:2224-2228, OBJECT_CARD_W WW:79), over a tab or alone (WW:2284-2288). A half kind (lock, preview) is 220, over a wider tab's card as an item card lies (WW:2226, 2232-2235). A tab's own card is held in to 220 where the window can't keep 180 units of inventory beside the full card (WW:2267-2271); the object card skips that rule.

**Mouse (OC:1575-1628):** hit-tested from the raw mouse every frame drawn (update runs every 100 ms), fired on release over the pressed zone; zones with drag follow the held mouse; the wheel goes to a zone with wheel, else the body's scroll.

**Keys (OC:1639-1672):** a kind with onKey gets the keys while the pointer is over the card (the lock's digits); armKeys wraps the World window's key handlers.

**Settings:** hidden actions (folded, all, hide); the Devices row (Immersive or Simple, which is Lite: Settings.lua:686-688) for the laundry's face; UI scale, text size, theme, language.

**Lite:** no branch in the host.

**Pad (buildFocusables OC:1677-1711):** every zone with a fid and no nofocus is a stop; while a question is up only the band's zones are (OC:1684). A runs the zone; B cancels a question, else closes the card (OC:1693-1695); its prompt reads "Close card" (OC:1700, ZUI:2110). A knob zone (knob, canTurn) becomes a grab-and-turn stop (OC:1703-1707, FM:982-1022). The opening stop: the kind's openFocus, else the main verb, else oc:back (OC:1408-1414). Host ids: oc:back, oc:pop, oc:prev, oc:next, oc:verb:<id>, oc:more, oc:hv:<id>, oc:confirm:no, oc:confirm:yes, oc:foot:<id>; oc:face is nofocus (OC:200-204).

**Small screens:** see the half card above. At 1280 wide the window is capped at 640 (WW:2806, 3952), so a full card leaves 640 - 36 - 36 - 480 = 88 units for the inventory beside it, under the 180 the tabs keep (WW:78).

### OC 2. Against the game (steps)

| Job | Game | ZeD host |
| --- | --- | --- |
| Close the small window | Its X (1), or B on a pad where the window takes it | X (1), B (1) or walk past the leash (0) |
| Go to the next one of a kind | Close, walk, open its menu again (3+) | Next or Previous (1) while two are in reach |
| See why an action is grayed | The menu's tooltip | The NEEDS line (folded by default: 1 to open) |
| Answer a "really?" | Only some game actions ask | The band's question, focus on Cancel (OC:946) |

ZeD has, the game doesn't: one place for every small window, browse among the same kind, the hidden-actions rule, a question before the acts that can't be undone, the leash hold during a walk. The game has, ZeD doesn't: its small windows can be moved and several open at once; none closes by distance (the placement window does, EPU:399-402).

### OC 3. States to sweep

- **Open:** each kind from each way in; one over another; over each tab; over the Loot view with multi-column Loot open; with an item card up.
- **Close:** X, B, a verb that closes, walking off (each leash), another floor, a tab switch, an item picked in Loot, a second column, the World window's close box, roll-up, the window shut while a card waits, death, entering a vehicle.
- **The hold:** a walk started from the card past the leash; a far walk started elsewhere with the card open; a long action started elsewhere.
- **Questions:** open, then the mouse, the wheel and the keys on the body while it asks; Yes after the target changed.
- **Header:** two and three of a kind at 220 and 480, Small and Large text, a long name.
- **Pad:** the opening stop of every kind; B with and without a question; a knob grabbed.
- **Layout:** 1280x720 and 1280x800 at UI scale 1 and 2, Large text, the inventory drawer open and shut, every full kind and both half kinds; 4K; the Deck.
- **Settings:** hidden actions folded, all, hide; Immersive and Simple (Lite).
- **Languages:** EN, DE, FR, RU, JP for the header, the band, the question.
- **Themes:** Dark, Light, High contrast.
- **MP:** split screen with a card on each player's window.

### OC 4. What the tests check already

| Script | What it checks |
| --- | --- |
| card_title_fit_sim | headFit at 220 and 480, Small and Large: which buttons drop and that a dropped one has no zone |
| object_card_fill_sim | The drawer's width for a full and a half kind; the card fills it at 4K, 1080p and the Deck; a half kind over a 480 tab |
| zedqa_two_widths | Every object card in reach is 220 or 480 and moves no window; a held-in window gives every tab the half card |
| knob_grab_sim | A grabs, the D-pad turns, A or B lets go, through the card's stops (the lock's wheel) |
| coverage_bugs_sim (296-334) | OC.browse and OC.tick wrap past the first item (Kahlua's %) |
| bx_fire (1404-1423), bx_cook (1073-1081) | The leash closes the fire card ten tiles off; Put out pressed twice in one frame |
| zedqa_cov_objcards | How a press is judged: verbs, the question's two buttons and the close key through the card's own press |
| zedqa_world_pad_take (405-430) | A card opens with the pad on its main live verb (the lock card) |
| rt_cards | Generator, fire and laundry open the game's way at 220 or 480 |

**Gaps:**
- The World window's close box, roll-up and death with a card open: no script checks what each kind's onClose leaves behind.
- The full card at 1280x800 with the inventory open (the held-in case is checked for tabs only).
- The question with the mouse, the wheel or the keys on the body while it asks.
- The hold with a walk or an action started away from the card.
- B on each kind (what B ends: a trade, a placement).
- Lite and the Light and High contrast themes on any object card; languages other than EN.

### OC 5. Suspicions (to prove in the game)

- **OC1:** A question doesn't freeze the card. Only the pad is fenced to the band (OC:1684); the mouse still hits every body zone (zoneAt OC:1557-1564), the wheel still turns a zone with wheel (OC:1622-1628) and the keys still reach onKey (OC:1639-1652). Yes runs the verb on the target as it reads at the press (OC:1525-1533). On the lock card that means a code changed after the band stopped showing it (LK1). Prove: open the Lock question, roll the wheel over a padlock wheel, press Yes.
- **OC2:** Closing the World window skips the card's onClose. _closeWorldWindow (WW:3908-3927) ends the Mechanics looks and the build cursor but never calls dropObjectCard or setEntry(nil), so def.onClose (OC:889-892) never runs: the placement card's save and gizmo cleanup are lost (PL1), the laundry's focus return goes, the medic's stream is left to MC.tick (MD3). A rolled-up window stops drawing the card, and OC.tick runs only in its prerender (OC:1381): no leash, no valid(), no refresh until it unrolls (zedqa_cov_objcards notes this in its header, lines 25-27). Prove with each kind open: the close box, the curtain's roll, U to toggle.
- **OC3:** B ends what the card holds, with no question. Every stop's B closes the card (OC:1693-1695) and its prompt says "Close card" (OC:1700); on the trade card that is Cancel for both players (TD1), on the placement card it is Done. Prove B from a row deep in each card.
- **OC4:** The full card ignores the held-in rule. A full kind asks for 480 over a tab or alone (WW:2224-2228, 2284-2288) where a tab is held to 220 (WW:2267-2271); at 1280 wide, inventory open, that leaves 88 units of inventory (WW:78-79, 2806). At UI scale 1.25 the card alone (600) passes the 640 cap less the strips. Prove at 1280x800, scale 1 and 2, Large text, with the laundry, medic, trade, placement and track cards: does the inventory squeeze, hide or the window pass its cap.
- **OC5:** The leash hold covers any action, not this card's. busy is any queued action (OC:279-284), so a far walk or a long action started away from the card holds it open; its verbs then act on the far object (each press walks back to it). Prove: laundry card open, a right-click Walk to ten tiles off.
- **OC6:** A body control reads its old state for up to 250 ms. Only a verb's press refreshes 50 ms later (OC:958); a body zone runs straight from the mouse (OC:1612) or A (OC:1692) and the kind refreshes on its beat (OC:63, 290-295). A second press in that time sees the first one undone in the face's reading (LA1).
- **OC7:** Opening any card leaves multi-column Loot and clears the item selection (WW:6586-6590). Prove: three columns open, the locked crate's row (lock card), back: the columns are gone.
- **OC8:** Entering a vehicle closes every kind but medic and trade (OC:272), the recipe preview too, though the Craft tab works seated. Prove a craft preview from a car seat.

---

## LK. The lock card (ObjectCardLock.lua, combination and key padlocks)

### LK 1. What it does

**Getting there:**
- The game's world menu Use Combination Padlock and Remove Combination Padlock (built in Java), through ISWorldObjectContextMenu.onPutDigitalPadlock, onRemoveDigitalPadlock and their WalkToComplete functions, hooked (PD:33-52): the card opens (set mode for Use), with the walk only when the crate is past 3.5 tiles (LK.openFor LK:712-715, OC:183-194). Safe mode and no World window: the game's ISDigitalCode (PD:18-26).
- The World window's container strip and its pad: a locked container's button opens the card instead of its contents (WW:537-541, 566, 608, 634, 4356-4358). Locked means the game's rule: an IsoThumpable locked to the character, a key padlock open to whoever carries its key (WW:3118-3126; the world menu's Take all uses the same rule, ItemMenu.lua:249-256).
- The game's key padlock menu entries (Use Padlock, Remove Padlock: WOCM:1605-1619) are not hooked: they run the game's own action, no card.

**Data (refresh LK:136-224, every 250 ms):** the code (getLockedByCode), codeLocked, keyLocked (isLockedByPadlock), canPad (canBeLockByPadlock), lockedToMe, a Combination Padlock in the main inventory (FindAndReturn, LK:78), a key padlock with keys (the first "Padlock" found, LK:79-83), the key (haveThisKeyId), the name (getEntityDisplayName, else the container's title, LK:64-74), the items, weight and capacity, the running padlock action on this object (anywhere in the queue, LK:117-134). Mode: enter (code lock), key (key lock), set (setting a code on a free crate), open (no padlock) (LK:178-182).

**The view:**
- The padlock drawn as hardware (LK:421-523): shackle up in set mode, three number wheels with chevrons; a key lock shows a keyway; no padlock shows an empty striped plate "No padlock on it" (LK:649-667).
- A busy band while a padlock action runs (LK:548-600): the job's words ("Locking", "Trying 3 1 9", "Walking over"), its bar and percent, Stop (clears the whole queue, LK:570-571).
- In set mode: "Locked to everyone, you included, until the code takes the padlock off" (LK:671-683, ZUI:1525).
- What it locks: the container's name with items and weight (hidden while locked to him), the padlock's state, the key (LK:686-703).
- The state tag: Setting a code, Code lock (red), Key lock (amber with the key, red without), Unlocked (green) (LK:299-307).
- The band: Walking over or Working, Ready to lock it with 3 1 9, Ready to try 3 1 9, Wrong code: 3 1 9. The padlock stays on., Ready to remove the padlock with its key; for 6 s after the code comes off, "Padlock off. It shows in the Loot pane." (LK:314-336).

**Verbs (LK:190-223):**
- Lock (set): asks "Lock the container? It shuts to everyone." (ZUI:3984), then LK.lock: walkAdj, ISPadlockByCodeAction lock with the code (LK:227-234), as the game's onSetDigitalCode (WOCM:1580-1587). Grayed for no Combination Padlock or a code of 000.
- Remove padlock (code lock): LK.try: walkAdj and the game's ISPadlockByCodeAction unlock with the dial's code on every try (LK:238-250); the card reads the outcome 150 ms after the action's perform (LK:156-167). The game compares the code first and queues nothing when it is wrong (WOCM:1589-1598).
- Remove padlock (key lock): the game's onRemovePadlock (LK:206-208, WOCM:1613-1619); grayed without the key.
- Use combination padlock (open): to set mode (LK:211-214). Use padlock (open): the game's onPutPadlock with the first key padlock (LK:215-221, WOCM:1605-1611).
- Wheels: a click on a chevron turns it; the mouse wheel over a wheel turns it; number keys over the card type left to right, Backspace steps back (LK:252-291). Turning is refused while a padlock action runs.
- The code comes off: the container is selected in the Loot pane (LK:169-173). A lock just set: the wheels go back to 0 0 0 (LK:175).

**Leash:** 4 tiles (LK:57).

**Lite:** no branch.

**Pad:** opening stop lk:wheel:1 in set and enter modes (LK:308-312), else the main verb. lk:wheel:1-3 are knobs: A grabs, the D-pad turns, A or B lets go (LK:497-513, FM:982-1022); lk:up / lk:dn are nofocus; lk:stop on the busy band; oc:verb:lock, oc:verb:remove, oc:verb:usecombo, oc:verb:usepad; the question's oc:confirm:no / yes.

**Small screens:** the half card (LK:57). The padlock's shape is 186 of LOCK_W's 236 units, drawn centered into a 200-unit body (186 beside a scrollbar) (LK:46-56, 427); facts stack under their labels below 300 units (LK:605-628); the busy words take rows of their own (LK:556-563); a long question wraps above the band (OC:1289-1313).

### LK 2. Against the game (steps)

| Job | Game | ZeD lock card |
| --- | --- | --- |
| Put a combination padlock on | Right-click (1), Use Combination Padlock (1), the walk, three boxes (3+), OK (1) | The same menu (2); three wheels (3 keys, or up to 15 clicks), Lock (1), Lock in the question (1) |
| Take it off with the code | Right-click (1), Remove Combination Padlock (1), three boxes (3+), OK (1) | The menu (2), or the locked crate's strip button (1); the wheels (3), Remove padlock (1) |
| A wrong code | The dialog shuts, nothing happens, no word, no time spent; start again (5+) | "Wrong code: 3 1 9" in the band, the dial kept; one wheel (1), Remove (1); each try 20 ticks |
| A key padlock on or off | Right-click (1), Use or Remove Padlock (1) | The same game menu (no card); the card's Remove padlock only when it opened on a key lock |
| Know who it shuts | Nothing says so | The set note and the fact line: locked to everyone, you included |
| Look inside a locked crate | No | No ("hidden while locked") |
| Pad: set a code | ISDigitalCode's boxes with the pad | A on a wheel (1), D-pad turns, A (1) per wheel, up to Lock (1+), A, Right to Lock in the question (1), A |

ZeD has, the game doesn't: the wrong-code line, the dial kept between tries, the warning that it shuts him out too, the container's contents line, the locked crate's strip button. The game has, ZeD doesn't: a free wrong try; the queue cleared before the walk (WOCM:1541, 1566; the hook doesn't, PD:34-41).

### LK 3. States to sweep

- **Crates:** a wooden crate, a small metal locker, a counter, a bar; free, code-locked, key-locked; a crate that takes no padlock.
- **Inventory:** no Combination Padlock; one in the main inventory; one in a backpack only; two; a key padlock with keys, one with no keys ahead of one with keys; the key in the main inventory, on a key ring, in a bag.
- **Codes:** 000, 001, 999; right; wrong; right after three wrong; typed with keys, wheels, chevrons, pad.
- **Presses:** Lock twice; Remove twice; Stop mid-walk and mid-action; a wheel turned during the question; a key typed during the question.
- **Distance:** at the crate; 3 tiles; 5 tiles (walk then open); walking off past 4 during the try.
- **Changes while open:** another player puts or takes the padlock off; the crate picked up or destroyed; the padlock item dropped mid-walk.
- **Pad:** the opening stop; grab, turn, let go each wheel; up to Lock; the question.
- **Layout:** 1280x800 Large text, the busy band, the set note, a long container name; the half card over a 480 tab.
- **Languages, themes:** EN, DE, RU (the facts and band words); Dark, Light, High contrast (the padlock's printed colors).
- **MP:** lock, try right, try wrong, key padlock, all on a server; two players at one crate.

### LK 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_padlock | Staging only: a free crate, a locker on code 319, a crate on a key padlock without its key, two Combination Padlocks and a Padlock with two keys |
| zedqa_m1_cards (1) | The lock card on each of the three is the half card; pictures |
| knob_grab_sim (LOCK) | A padlock wheel through the card's stops: grab, turn, let go |
| zedqa_world_pad_take (405-430) | The card opens with the pad on the main live verb |
| loot_l1_sim (L1-2) | The world menu's lock rule: key holder opens, no key stays shut, a code lock stays shut |
| zedqa_padmap, zedqa_deep_run | The card's stops listed on a staged crate |

**Gaps:**
- No script presses Lock, Remove padlock (code or key), Use combination padlock or Use padlock; none reads the wrong-code line.
- The game's world menu entries that are hooked (Use and Remove Combination Padlock) never pressed; the locked crate's strip button never pressed.
- A Combination Padlock in a bag; a key on a key ring; the queue before the walk.
- The question with the wheel or keys; Stop mid-try.
- MP: nothing.
- Lite, Light and High contrast, any language but EN.

### LK 5. Suspicions (to prove in the game)

- **LK1:** A crate locked with a code he never read. The band's "Ready to lock it with 3 1 9" gives way to the question "Lock the container? It shuts to everyone." (LK:320-322, ZUI:3984), which names no code. While it asks, the mouse wheel over a wheel, a chevron and the number keys still turn the dial (OC1; LK:513, 517-520, 273-291; turn refuses only while busy, LK:253), and LK.lock reads the dial at Yes (LK:228). The crate then shuts to everyone, him included, with a code found only by trial at 20 ticks a try (LK5). The game's OK uses the code in front of him (WOCM:1582-1584). Prove: Lock, roll the wheel once over wheel 3, Yes; read getLockedByCode.
- **LK2:** On a server a right code can read as wrong, and Lock can stay lit after it locked. The try's result is read 150 ms after the client's perform (LK:158-161); the code comes off in the action's complete() (PBC:30-35), which runs on the server in B42, and PBC sends no thump:sync() where the key padlock's action does (PA:35, 47). If the change lands late the band says "Wrong code: 3 1 9. The padlock stays on." for the right code, then flashes "Padlock off". If it lands late after a Lock, the card stays in set mode with Lock lit (LK:176-182) and a second Lock spends a second Combination Padlock from his inventory (LK:229, PBC:26). Prove on a server: right code once, Lock once, the latency between perform and the client's getLockedByCode.
- **LK3:** Someone else's unlock reads as his. Any change from locked to free flashes "Padlock off. It shows in the Loot pane." and selects the container in his Loot pane (LK:169-173), whoever took it off. Prove with two players at one crate.
- **LK4:** The NEEDS lines say "in your bags"; the rule is the main inventory. comboPadlock and keyPadlock use FindAndReturn on getInventory (LK:78-83), as the game's action removes it from there (PBC:26), but the words are "a Combination Padlock in your bags", "a padlock with its keys in your bags" and "its key in your bags" (ZUI:3981-3983, LK:194-196, 207, 212, 216). A padlock in a backpack leaves Lock grayed with words that say he has what it needs. keyPadlock takes the first Padlock found and gives up when that one has no keys (LK:80-81). Prove: a padlock in a backpack only; two key padlocks, the first without keys; the key on a key ring.
- **LK5:** Every try is a timed action. A wrong code costs nothing in the game (WOCM:1592 compares before queuing); on the card each try is a walk if needed and 20 ticks (LK:238-250, PBC:45-47). A forgotten code (LK1) is found at up to 1000 tries x 20 ticks.
- **LK6:** The hook doesn't clear the queue first. The game clears it before the walk (WOCM:1541, 1566); PD:34-41 opens the card and openNear queues the walk behind whatever is queued (OC:188-190). Prove: a long action running, then Use Combination Padlock from 5 tiles.
- **LK7:** The pad's path is long and one comment is wrong. A on a wheel grabs it (FM:1003-1008); the zone's own run that "presses the card's verb" on a pad (LK:498-503) never runs. Lock sits in the verb row above the padlock; the question lands on Cancel (OC:946). Prove the walk: steps from the card's open to a locked crate, and that the help line names the grab.
- **LK8:** The half card has no slack beside a scrollbar. The padlock is 236 units drawn into a 200-unit body, its shape 186, and 186 is all a body beside a scrollbar has (LK:52-56, 427). With the busy band and the set note at Large text the body scrolls: prove the third wheel's chevrons and Stop stay inside at 1280x800 and the Deck.
- **LK9:** Scope, not a bug: doors, windows, door locks, keys, lockpicks and barricades have no ZeD surface (the scope note above). A sweep that wants "barricade lost" or "door left unlocked" has nothing of ZeD's to sweep there; the game's own menus stand.

---

## MD. The medical check card (ObjectCardMedic.lua)

### MD 1. What it does

**Getting there:** the game's way: right-click another player, Medical Check; they answer the game's question (a ZeD prompt); the game's ISMedicalCheckAction runs (150 less 2.5 per First Aid level ticks, MCA:85); its perform is hooked (TM:126-144): the card opens and the doctor starts receiving the patient's body as the game's perform does (MCA:72-74). Vanilla's health panel runs instead in safe mode, with no World window, with the World window open for another split-screen player or when the card can't open (MD:39-46).

**Data (refresh MD:136-161, every 250 ms):** HealthTab.gatherData on the patient's body (the remote copy on a server, MD:145) with the doctor's First Aid level (MD:147); the injury list and its words by vanilla's thresholds (HT:274-...: severity at First Aid 3, 5 and 7, infection at 9 or by the infection level, ISHP:633-830); each part's health; their pain at First Aid 5 or more (MD:152-159, ISHP:471).

**The view (MD:284-343):** the figure in its frame, each part tinted by its health, the wounds marked on the patient's skin; beside it the part under the pointer or the pad (HT's detail view), else the summary: Overall with its bar and the game's word, the wounds counted, their pain (MD:233-250); then the injury list: a dot, the part's name, its health in percent, its condition tags (MD:253-282). The header: "<name>'s Health" (the game's words, MD:163), a stethoscope icon, the overall percent as the tag (MD:168-173). More than 2 tiles apart: the game's "too far away" words in a warning box and the band (MD:117-127, 175-178, 286).

**Verbs:** none in the verb row. A part on the figure or a row opens the game's own treatment menu for it (ISHealthPanel.doBodyPartContextMenu through an adapter: doctor as doctor, patient as patient, HT:937-972); not while paused (MD:193-194, as ISHP:170-172).

**Closing (valid MD:103-129):** either of them moves half a tile from where they stood at the check's end (not a staff member who may check from afar, not two people seated in one car), or the patient leaves and comes back; as the game's panel (ISHP:351-377). No leash (no square). In a vehicle it stays (vehicleOk, MD:36). Gone by any path, the doctor stops receiving the body (MD:59-78, 132-134).

**Lite:** no branch.

**Pad:** opening stop: the worst injury's row, else the chest on the figure (MD:181-185). mc:fig:<figure part> on the figure (MD:318-324), mc:part:<part> on the rows (MD:279-280); A opens the treatment menu at the stop (MD:195-200); B closes the card.

**Small screens:** a full card (480). The figure frame stacks over the text only on a card narrower than halves (MD:290-292), which the drawer never gives it.

### MD 2. Against the game (steps)

| Job | Game | ZeD medic card |
| --- | --- | --- |
| Check another player | Right-click (1), Medical Check (1), their Yes, the action | The same; the card in the World window |
| Treat a part | Right-click its row (1), the treatment (1), the item (1) | Its row or figure part (1), the treatment (1), the item (1) |
| Pad: treat | A on the list row (the menu at the panel's corner, ISHP:928), the option (1) | A on the row or the part (1), the option (1) |
| See a treatment running | The part's row shows its job and bar (ISHP:595-601) | Nothing on the card |
| Read how hurt they are | A damage word (ISHP:445-451) | The overall percent, each part's percent, the word |
| Close | X or B | X, B or either of you moves |

ZeD has, the game doesn't: the figure with wounds and care marks, the part's detail beside it, each part's health in numbers, the worst injury first on the pad. The game has, ZeD doesn't: the running treatment's bar on its part; the "nothing fits" silence is the same on both (HT:970 says it only for one's own body).

### MD 3. States to sweep

- **Patients:** a scratch, a laceration, a deep wound, a bite, a fracture with and without a splint, glass, a bullet, a burn, an infected wound, stitches, a bandage dirty and clean; pain 0 to 4; a strained part.
- **Doctors:** First Aid 0, 3, 5, 7, 9; a staff member on a server.
- **Places:** side by side; two in one car, one driving, one a passenger; 3 tiles apart (staff); the patient steps away and back; the doctor steps; a zombie shoves either.
- **Presses:** a treatment pressed twice on one part; a treatment during another; while paused; with nothing that fits.
- **Changes while open:** the patient bandages himself; leaves the server and comes back; dies.
- **Pad:** the opening stop; every figure part; every row; A, the menu, B; B on the card.
- **Layout:** 1280x800 with the inventory open; Large text; a long name.
- **Languages, themes:** EN, DE, JP (the part names and tags); Dark, Light, High contrast (the figure's tint).
- **MP and split screen:** a server; split screen in SP; split screen on a server; two doctors at once.

### MD 4. What the tests check already

| Script | What it checks |
| --- | --- |
| trade_medic_sim (medical part) | With the game's own files on stubs: the action's end opens the card, not ISHealthPanel; the doctor receives the body; the remote body; the figure layout; the card closing on a move |
| zedqa_b8_mp_medic | On a server against a second client: the card and injury list at First Aid as is, then at 5 (severity words, pain), the treatment menu, a bandage; 3 tiles apart; the World window shut mid-check; safe mode gives the game's panel |
| figure_frame_sim, strain_tint_sim, woundsov_sim, chip_dot_sim | The figure frame, the strain tint, the wound marks and the dots, shared with the Health tab |
| object_card_fill_sim | The card fills its drawer |
| hg_treat, vk8_wounds | The Health tab's own treatment menu (one's own body) |

**Gaps:**
- First Aid 3, 7 and 9 against the game's thresholds part by part; an infected wound below 9.
- A treatment pressed twice; a treatment while another runs.
- Split screen; two doctors; a seated check.
- The pad end to end (the menu's place and focus after B).
- 1280x800; Lite; Light and High contrast; languages but EN.
- zedqa_b8_mp_medic is from Nov 8; the figure tint and frame changed Nov 22-23.

### MD 5. Suspicions (to prove in the game)

- **MD1:** No sign of a running treatment, so a second press spends a second item. The game's row shows the job and its bar under the part (ISHP:595-601, from the panel's actions table); the card's adapter keeps actions = {} and nothing reads it (HT:947), and the card has no band for it. A click on the same part again offers the same treatment and queues a second one: a second bandage, disinfectant or suture thread. Prove: bandage a part, click the part again during the action.
- **MD2:** Exact numbers the game never gives a doctor. Each row shows the part's health in percent (MD:274), the header tag the overall percent (MD:168-173) and the summary its bar (HT drawOverall); the game shows its damage word (ISHP:445-451) and part numbers only in cheat (ISHP:589-593). A doctor at First Aid 0 reads exact health. Prove against the director's intent and the classifier's words at 0, 3, 5, 7 and 9 (HT:274-...).
- **MD3:** The stream can outlive the card. MC.current holds one check (MD:52); MC.tick ends only that one when its card is gone (MD:67-78). With two checks in split screen, the first one's stream stays on after the World window closes (OC2 skips onClose). A rolled-up window runs no valid() (OC2): the doctor can walk off and the check stays until it unrolls.
- **MD4:** The pad's treatment menu. A opens the game's menu at the stop's corner (MD:195-200); prove it opens on screen at the card's right edge and where focus goes after B on the menu.
- **MD5:** Paused or nothing fits: the press does nothing and says nothing (MD:193-194; HT:970 speaks only for one's own body). Low.

---

## LA. The laundry card (ObjectCardLaundry.lua: washer, dryer, washer-dryer)

### LA 1. What it does

**Getting there:** the World window's container buttons: for a machine with a face (LA:81-84) the game's four laundry buttons give way to one "Controls" gears button (CT:517-578, LA:669-679) that opens the card (LA:659-665). Also the pop-out: a click on the machine in the world, A at it, the header's full-view key (FacePop). The game's world menu entries (WOCM:1113-1185) are not hooked: they still run the game's actions.

**Data (refresh LA:156-179):** activated (isActivated), powered (the container's isPowered), water and capacity (getFluidAmount, getFluidCapacity; on the pipes 10000 of 10000 reads "On the water pipes", LA:166), washer mode (a washer, or the washer-dryer in washer mode), the items inside (count only), the name (getMoveableDisplayName, LA:89-97). canToggle = powered and (water or not washer mode); canMode = washer-dryer and powered (LA:175-176). No verbs: the face is the control surface (LA:178).

**The view:**
- The machine's front in pixel art at a whole zoom (fitFace LA:514-552), the room behind it (LA:487-503): the run lamp or the red no-power lamp, the water meter (dark without power) and the water in the drum, FILL in washer mode with no water, the clothes in the drum, the washer-dryer's WASH and DRY lamps.
- Phases ZeD invents: WASH, RINSE, SPIN for the washer and DRY, COOL for the dryer, 5 game minutes each, round again; the cycle dial follows; the drum turns once in 2 s of real time with the game running (LA:57-63, 216-241).
- Under the face: Water and Inside rows (LA:573-581).
- The tag: Running or Off (LA:183-187). The band: the game's "requires power nearby" or "requires a water supply" words (LA:194-201).
- Simple form (Lite: the Devices row, Settings.lua:686-688): the cycle phase in large type over a segmented bar, Power switch, Mode Wash | Dry, Water, Inside with Open (LA:605-647); same zones.

**Controls (LA:295-310), each the game's own action:**
- Power: walkAdj, then ISToggleClothingWasher, ISToggleClothingDryer or ISToggleComboWasherDryer (LA:134-140), as the loot handlers' perform (CWT:35-39). Off with no power or with no water in washer mode, as the game hides its button then (CWT:9-10, CWDT:9-10).
- Wash and Dry (washer-dryer): ISWorldObjectContextMenu.onSetComboWasherDryerMode, its own walk inside (LA:143-148); off without power and in the mode it is already in.
- Door: selects the machine's container in the Loot pane (LA:151-154), no walk.

**Leash:** 6. Browse among the machines within 6 tiles (LA:118-131).

**Pad:** opening stop ldy:power (LA:189); ldy:power, ldy:mode_wash, ldy:mode_dry, ldy:door; oc:pop; closing the card returns focus to the gears button (LA:205-213).

**Small screens:** a full card. The face is the big one at the largest whole zoom that fits width and height, else the narrow face, never below 1x; the stencil clips what is left (LA:506-552).

### LA 2. Against the game (steps)

| Job | Game | ZeD laundry card |
| --- | --- | --- |
| Turn a washer on | The loot window's Turn On (1), the walk | Controls (1), Power (1), the walk |
| Set the washer-dryer to dry | Set mode: dryer (1) (hidden in washer mode with no water, CWDM:9) | Controls (1), DRY (1) (works with no water) |
| See the water in it | No reading | The meter, the drum and the Water row |
| See what is inside | The container in the loot window | Inside (count), Door (1) |
| Know the wash is done | The clothes' tooltips (dirt, blood, wetness) | No reading; the invented phases go round |
| Know why it won't start | The button is not there | The band and the help line say why |

ZeD has, the game doesn't: the face, the water reading, the reason it won't start, browse between machines, the washer-dryer's mode switch without water. The game has, ZeD doesn't: none of its buttons on the container row while the face is on (CT:522).

### LA 3. States to sweep

- **Machines:** a top-loading washer, a dryer, a washer-dryer in each mode; on the pipes, with a filled tank, empty.
- **Power:** grid on, grid off, a generator, the power cut while running.
- **Water:** none, a little, full, used up while running.
- **Clothes:** none, one, many; dirty, bloody, wet; after a wash, after a dry.
- **Presses:** Power twice fast (mouse and A A); Power during the walk; mode switch while running; Door from 1, 3 and 6 tiles.
- **Changes while open:** another player toggles it; the machine picked up; the power returns.
- **Pad:** the opening stop; every control; the return to the gears button on close.
- **Layout:** 1280x800 inventory open (OC4); 4K; the Deck; the narrow face; two machines (the header's browse at Large text).
- **Settings:** Immersive and Simple (Lite).
- **Languages, themes:** EN, DE, FR (the band, Water and Inside rows); Dark, Light, High contrast (the paper tone of the room).
- **MP:** two players at one machine.

### LA 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_laundry | Each machine in a room one square off: the gears button and none of the game's laundry buttons; the full card and the face by class; zones; power primary; no water and no power lamps, the band; the meter dark without power; FILL; clothes sprite; Door, Power on and off, phase lamps step, the dial, the drum; DRY then WASH; with useFace false the game's buttons return |
| rt_cards | The gears button opens the card: Off |
| face_popouts_sim | The face as a pop-out: its zones as controls, the primary first, faces off and safe mode |
| gc_qa_cleanup_sim, gc_cleanup | The room behind each face inside the face area and the scrolled view; the header keeps three letters |
| card_title_fit_sim | The laundry's header at 220 and 480 |
| zedqa_b17_scroll | The card's scroll |

**Gaps:**
- Power pressed twice; during the walk.
- The power cut or the water used up while running; whether the clothes come out clean, wet or dry; how long it takes.
- Door from past one square.
- The Simple form (Lite) pressed end to end.
- 1280x800; Light and High contrast; languages but EN; MP.
- zedqa_laundry is from Nov 8; the faces changed Nov 22 (whole zoom only).

### LA 5. Suspicions (to prove in the game)

- **LA1:** Power pressed twice turns it on and off. Each press is walkAdj and a toggle that flips isActivated (LA:134-140, TCW:25-30; isValid only checks the object, TCW:5-7). The face reads the old state for up to 250 ms (OC6), and the walk shows nothing on the card. A double click or A A during the walk queues two flips: the wash never starts, or a running dryer stops. Prove both with the mouse and the pad from 4 tiles.
- **LA2:** The cycle is invented and never ends, and the card can't say the clothes are done. WASH, RINSE, SPIN step every 5 game minutes and go round (LA:57-63, 216-232) from when this client first saw it running (LA:219-225); the game's machine runs until it is turned off, its water runs out or its power goes. The card shows only "n items" (LA:576, 642), not dirt, blood or wetness. A player who waits for SPIN to end waits forever; one who stops it at SPIN may take out wet clothes. Prove what the game does to each item per game minute and whether it ever stops itself.
- **LA3:** Running without power or water. The tag and lamps follow isActivated (LA:160, 185, 220-232); prove the game turns the machine off when the power is cut and when the water runs out, else the card says Running over a dead machine.
- **LA4:** The Door does nothing from farther than a square. selectContainer waits up to 120 tries for the container in the Loot list (LA:151-154), which holds only what is within a square (zedqa_laundry header line 5); the leash is 6. No word when it never shows.
- **LA5:** The washer-dryer switches mode where the game won't. The game hides Set mode in washer mode with no water (CWDM:9); the card allows it with power (LA:176, 303-305). Kinder than the game; note it as a difference, and prove the game's action accepts it (ISSetComboWasherDryerMode isValid checks only the mode and the object).
- **LA6:** MP: each client's phases are its own (LA:66, 219-225), so two players at one machine see different lamps and dials.

---

## PL. The placement card (ObjectCardPlacement.lua, Extended 3D Placement)

### PL 1. What it does

**Getting there:** right-click an item lying in the world with a 3D model, clothing or a weapon, Extended Placement (the engine's option, built in Java); the game walks next to it (ISExtendedPlacementAction, EPA:15-29), whose perform is hooked (FU:109-122): the card opens instead of ISExtendedPlacementUI. Pad players get the option back in the world menu (the engine leaves it out for them) and on a ground item's menu in Loot, for everyone (FU:39-105).

**Data (PL:32-59, 97-105):** the item's place in its tile (getOffX, Y, Z) and turn (getWorldX, Y, ZRotation), kept at open for Revert (rounded to 3 places as the game's, EPU:484-489); the name and icon.

**The view (PL:200-229):** Movement (Within the tile) with X, Y and Z, Rotation (Degrees) with X, Y and Z: each row a label, a slider with quarter ticks, the readout (0.00 or 0 to 359 degrees) and -0.01 / +0.01 or -15 / +15 nudges (PL:135-198). The game's gizmo in the world: the move arrows while he works in Movement, the turn rings in Rotation (by the pad's focus, else the pointer's height, PL:206-220); dragging it writes back (PL:44-57).

**Verbs (PL:99-104):** Done (closes, which saves), Revert (back to the place and turn at open, PL:91-95). Closing by any path the host runs onClose saves: setDoingExtendedPlacement(false), syncExtendedPlacement, the gizmo put away (PL:114-120), as the game's close (EPU:454-462).

**Leash:** 3 (PL:30); the game's window closes past 3 by DistToProper (EPU:399-402).

**Lite:** no branch.

**Pad:** opening stop p3:move:x (PL:108); p3:move:x / y / z and p3:turn:x / y / z (sliders: Left and Right step 0.05 or 15, PL:190-196), p3:<section>:<axis>:- and :+ (nudges), oc:verb:done, oc:verb:revert; B closes (saves).

**Small screens:** a full card; sliders take what is left after the label, readout and nudges (PL:166-167).

### PL 2. Against the game (steps)

| Job | Game | ZeD placement card |
| --- | --- | --- |
| Open it | Right-click (1), Extended Placement (1), the walk | The same; pad players get the option too |
| Move it a little | Drag the slider or type in the box (1) | A nudge (1) or a drag (1) |
| Set an exact value (0.5, 90) | Type it in the box (1 + typing) | Drag to it, or up to 50 nudges; no box |
| Turn it 90 degrees | Type 90 (1) | +15 six times (6), or drag |
| Undo | Revert (1) | Revert (1) |
| Finish | Close (1); B on a pad removes the window without its close (EPU:414-419) | Done (1), B (1), X (1) or walk away |

ZeD has, the game doesn't: nudges, the pad on every slider, B that saves, the card closing saves on every path but one (PL1). The game has, ZeD doesn't: typed values; Escape to close (EPU:497-507).

### PL 3. States to sweep

- **Items:** a hammer, a bottle, a jacket, a weapon, a big item; on the floor, on a table, upstairs.
- **Values:** 0 and 1 on each move axis; 0, 345, 360 and a negative saved angle on each turn axis; Revert after each.
- **Gizmo:** drag the arrows and the rings; the group following the pad and the pointer.
- **Close:** Done, X, B, walk past 3, another floor, a tab switch, the World window's close box, roll-up, another card opening.
- **Changes while open:** another player picks the item up; the item burns.
- **Pad:** every slider and nudge; Left and Right on a slider; from the world menu option ZeD adds.
- **Layout:** 1280x800 inventory open; Large text.
- **Languages:** the section heads (the game's) and ZeD's axis letters and nudge labels in DE, FR.
- **MP:** a second client watches the item while he places it and after each way of closing.

### PL 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_cov_objcards (placement) | The game's Extended placement on a hammer opens the card; it starts from the item's place and turn; Done is the main verb; the pad lands on Movement X; +0.01 X, +15 Z and the D-pad on Y move by those steps and the gizmo follows; Z never under the floor; -15 from 5 wraps to 350; Revert; Done closes and keeps it; past 3 squares it closes |
| zedqa_two_widths | The card at 480 |
| menu_marks_sim, pad_b19_sim, pad_audit_228_sim | The added world menu option and the card's stops |

**Gaps:**
- Saving on each way of closing; the World window's close box and roll-up.
- MP: what a second client sees.
- The gizmo dragged.
- 1280x800; languages but EN.

### PL 5. Suspicions (to prove in the game)

- **PL1:** Closing the World window loses the save and leaves the gizmo. onClose never runs (OC2), so syncExtendedPlacement (PL:117) is skipped, the gizmo stays registered (PL:119) and the item keeps setDoingExtendedPlacement(true) from driveGizmo (PL:125). On a server the other players keep the old place. Prove: move the item, close the World window with its close box and with U, look from a second client, then try to pick it up.
- **PL2:** No typed values. The game has a number box per axis (EPU:30-40, 83-93, 202-249); the card has a slider and nudges only (PL:21-22, 146-160). An exact place takes a drag at slider precision or many presses; the pad steps 0.05 and 15 (PL:190-196).
- **PL3:** The leash is looser and can be held. 3 + 0.5 tiles from the square's center (OC:285) against the game's 3 by DistToProper (EPU:399-402), and the hold (OC5) keeps it past that while any action runs.
- **PL4:** The item taken while the card is open: valid() closes it (PL:61-63) and onClose calls setDoingExtendedPlacement and syncExtendedPlacement on an object no longer in the world (PL:115-118; the sync in a pcall). Prove nothing throws on the server and the item in his inventory is not left flagged.
- **PL5:** The pad's added option: placeable() checks a wall only between his square and the item's (FU:44-45), up to 12 items (FU:37). Prove an item two squares off behind a wall against the engine's own rule for the mouse.

---

## TK. The track card (ObjectCardTrack.lua, Inspect Track)

### TK 1. What it does

**Getting there:** the game's ISInspectAnimalTrackAction (search mode's icon, a track on the ground, a track item such as droppings or fur; 100 less 1.5 per Tracking level ticks, IATA:50-55): its perform is hooked (AN:48-61, 92): the card opens instead of ISAnimalTracksUI.

**Data (TK:53-71):** Tracking level; the track's type (IGUI_AnimalTracks_<type>); its direction (getDir); the species by the game's rule (the species from Tracking 5, else the track size, "???" for a type the game doesn't know: TK:61-67, ATU:48-58); freshness (getFreshnessString at his level).

**The view (TK:109-151):** the track's picture, a compass with the eight points and the way it went lit (TK:83-107); facts: Type, Animal (with "| Tracking n"), Freshness, Direction (the game's own words for the eight points, the weather radio's AEBS_zone_name_* keys). Title: the track's type. Tag: the freshness, green (TK:76-80).

**Verbs:** none.

**Leash:** 6 for a track on the ground or a track item lying there; none for one he carries (TK:36-43). The game's window never closes by distance.

**Lite:** no branch.

**Pad:** oc:back only (no verbs, no body stops); B closes.

**Small screens:** a full card; the picture column is 140 units, values start 96 units into the facts and are not cut (TK:113-137).

### TK 2. Against the game (steps)

| Job | Game | ZeD track card |
| --- | --- | --- |
| Inspect a track | Right-click or the search icon (1), Inspect (1), the action | The same; the card opens |
| Read the way it went | "N" in text | The compass and the word |
| Close | Its X (1) | X (1), B (1) or walk 6 tiles |
| Pad | No pad support in the game's window | B closes |

### TK 3. States to sweep

- **Tracks:** a footstep, droppings, fur, a dead animal's trail; each species; fresh, hours old, days old.
- **Tracking:** 0, 4, 5, 10.
- **Where:** on the ground, a track item on the ground, a track item in the bag; picked up after the card opened.
- **Changes while open:** the track fades or is removed.
- **Layout:** 1280x800 inventory open; Large text.
- **Languages:** DE, RU, JP (the species and freshness words, the compass letters).
- **Themes:** Dark, Light, High contrast (the compass).

### TK 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_cov_objcards (track) | With a stand-in for the game's track item: the action opens the card; title, direction, Tracking level, the species rule at 5 and the size below, "???"; the tag is the freshness; no verbs; no leash when carried (open 9 squares off); the close key closes |

**Gaps:**
- A real track on the ground (the drag strip has none); the leash at 6; a track item picked up after opening.
- Languages but EN; Large text; 1280x800.

### TK 5. Suspicions (to prove in the game)

- **TK1:** The tag is green whatever the freshness (TK:79): a days-old track reads as a good state. The game's window draws it as plain text (ATU:35-36).
- **TK2:** Values are not cut (TK:137): a long species or freshness at Large text in DE or RU runs to the card's edge and is clipped by the body's stencil.
- **TK3:** A track item that changes hands: t.sq is the world item's square at open (TK:40-41), so one picked up after the card opened closes the card 6 tiles from where it lay though he carries it; valid() is always true for an item (TK:50), so one eaten or gone keeps its card. Low.

---

## TD. The trade card (ObjectCardTrade.lua with ZeD_Trade.lua, multiplayer)

### TD 1. What it does

**Getting there (TM:43-121):**
- Right-click a player, Trade with: ISWorldObjectContextMenu.onTrade, hooked: the card opens blocked ("Waiting for X's answer."), requestTrading (ZT:84-127).
- Their request: the game's question (a ZeD prompt); Yes is ISTradingUI.onAnswerTradeRequest, hooked: any open trade ends first, the card opens, acceptTrading (TM:60-86).
- The game's trade events (AcceptedTrade, TradingUIAddItem, TradingUIRemoveItem, TradingUIUpdateState) go to ZeD's session when the player's trade is ZeD's, else to the game's handlers (TM:91-121).
- The game's guards stay on: a stand-in element sits in ISTradingUI.windows, visible while the trade is open, so the game's menus and transfers refuse as with its window (ZT:96-113); a menu or a refused transfer brings the card back (TM:151-176).

**Data (ZT):** your offer and theirs (item objects), sealed and theirs sealed, blocked (waiting, closed, refused, gone) and too far (more than 2 tiles on either axis, ZT:439-444), the last thing that happened for a few seconds, the trade log, your main inventory grouped by name as the game's list (equipped first, key rings, hotbar, 20 of a kind; not worn, held, favorite or hidden: ZT:355-413; held and worn checked by id too, ZT:213-250).

**The view (TC:194-237):** the blocked words in a warning box, or the last thing that happened; your offer and theirs side by side (stacked under 400 units), each "n / 20" with its sealed line; your main inventory with Add (and Add all for a stack); the trade log, newest first. Header: "Trade with <name>" (the game's words), a swap icon, Waiting or Ready (TC:54-63).

**Verbs, all the game's calls (ZT):** Add (the game's rules one by one: 20 items, in the main inventory, not held, not a favorite, ZT:253-278), Add all (each in turn), Remove (ZT:288-300); the band: Seal offer (a check, ZT:303-311), Cancel (Close once it is over, ZT:165-169) and Accept deal (both sealed, something offered, ZT:314-328). Their add or remove unseals both sides locally, as the game (ZT:520-541, ITU:897-934).

**Pinned:** tab switches, item cards and other object cards leave the trade waiting; it comes back when they close, or when the other player does something (TC:36-38, ZT:452-484). A shut World window: the trade waits.

**Leash:** none; more than 2 tiles apart blocks it with the game's words. vehicleOk.

**Lite:** no branch.

**Pad:** opening stop: Cancel while blocked, else the first Add, else Seal offer (TC:66-72); tr:add:<group>, tr:all:<group>, tr:rm:<item id>, oc:foot:seal, oc:foot:cancel, oc:foot:accept. B on any stop closes the card, which is Cancel (TC:42-44).

**Small screens:** a full card; the offers stack below 400 units (TC:207-216).

### TD 2. Against the game (steps)

| Job | Game | ZeD trade card |
| --- | --- | --- |
| Start a trade | Right-click (1), Trade with (1) | The same |
| Add one item | Pick it in the list (1), Add (1) | Add on its row (1) |
| Add a stack | Pick its header (1), Add (1) | Add all (1) |
| Take one back | Pick it in your offer (1), Remove (1) | Remove on its row (1) |
| Seal | The tick (1), Y on a pad | The band's Seal offer (1) |
| Accept | Accept deal (1) | Accept deal (1) |
| Read the log | Trade Log (1), a second window | In the card |
| Pad: back out of a list | B moves focus | B ends the trade |

ZeD has, the game doesn't: one card with the log in it, why a button is grayed in the help line, the trade kept through other cards. The game has, ZeD doesn't: the Info help window (ITU:687-707); Y to seal.

### TD 3. States to sweep

- **Flow:** ask, their Yes, No, no answer; they ask, Yes, No; one trade open and a new request.
- **Offers:** 0, 1, 20, 21 items; a stack; a bag; an item held, worn, a favorite, in a bag; the same item twice; an item eaten or dropped after offering; a herbalist's berries.
- **Seal:** each side; their change after both sealed; Accept with one side empty.
- **Distance:** 2 tiles, 3 tiles, back; one in a car.
- **Hidden:** a tab switch, an item card, another object card, the World window shut, a right-click menu while shut.
- **Ends:** Cancel, B, X, their close, they leave the server, safe mode mid-trade.
- **Pad:** every stop; B from each.
- **Layout:** 1280x800 inventory open; Large text; 20 items each side.
- **Languages:** DE, RU (the game's trade words, ZeD's Main inventory and empty lines).
- **MP:** split screen on a server; a slow link (events in flight).

### TD 4. What the tests check already

| Script | What it checks |
| --- | --- |
| trade_medic_sim (trade part) | With the game's own files on stubs: Trade with, Yes and No, the game's guards, every add rule (bag, equipped, favorite, 20, twice), seal and unseal, their add, remove, seal, close and refusal, 2 tiles apart, an offered item that leaves the inventory, Accept, Cancel, the card closing, safe mode, the events routed; drawn full and stacked; its stops and grayed buttons |
| zedqa_b8_mp_trade | On a server against a second client: ask, wait, Yes, lists, add, 20, seal, their change unseals, both seal, Accept; distance; pinned through a tab switch and a shut window; Cancel; No; closed before the answer; safe mode mid-trade |

**Gaps:**
- B on the pad from each stop; the pad end to end (zedqa_b8_mp_trade leaves steps 14 and 17 manual).
- Split screen on a server.
- A server re-send of an offered item.
- 1280x800; languages but EN.
- zedqa_b8_mp_trade is from Nov 8; ZT changed Nov 25 (herbal names).

### TD 5. Suspicions (to prove in the game)

- **TD1:** B ends the trade for both players. Every stop's B closes the card (OC:1693-1695), the card's close is Cancel (TC:42-44, ZT:165-169) and sends WindowWasClosed, with no question; the prompt reads "Close card" (OC:1700) and the close key's help "Close this card" (OC:1090, ZUI:4103). The game's B doesn't cancel a trade (ITU:765-772: only Y is the window's own). A pad player backing out of a row loses the negotiated offers. Prove B on tr:add and on oc:foot:seal.
- **TD2:** Split screen on a server reads the first player's window. TR.canOpen, Session:finish and reshow call getWindow() and getObjectCard() with no player (ZT:76, 138, 463), and Session:update cancels the trade when canOpen turns false (ZT:424). Prove a second local player's trade: it should fall to the game's window, never open and cancel itself.
- **TD3:** An offered item re-sent by the server as a new object. isOffered compares objects (ZT:180-183) where the held check had to compare ids for that reason (ZT:203-212). The re-sent copy could show in the list again and go on the offer twice, or the old one be dropped by the "left your inventory" rule (ZT:446-451). Prove with a container update mid-trade.
- **TD4:** A trade the player can't see holds him. The World window shut or another card in the drawer: the trade stays open (ZT:452-478) and the game's menus refuse him until the card comes back on his next menu (TM:157-166). Prove the path from a shut window to the card and that nothing else in ZeD's menus is blocked silently.

---

## PV. The recipe preview card (ObjectCardPreview.lua)

### PV 1. What it does

**Getting there:** a click on the picked recipe's icon in the Build or Craft header, or A on it (CraftingCore's openPreview, FEATURE_MAP line 372). It closes with B, the close key, the icon again or another recipe picked (valid PV:43).

**Data:**
- A build recipe, once per card (PV:298): the build object's faces and their tiles (PV:57-104), the strength as the game sets it when it is built: the script's health, the bonus at the sandbox's Construction Bonus Points, the highest relevant skill level x the skill base health (PV:105-149, BIE:666-677); barricades none (PV:138-139); the skills it needs.
- A craft recipe, every refresh (PV:301): the item it makes (the mapper's result for what is in reach, PV:189-230), an instance of it for its facts (ZeD.itemFacts, PV:232-249), "or one of N others"; for an upgrade of one of his own items, the changes old to new with percent (PV:250-287).
- The verb's state from the drawer's own reading (PV:305-310).

**The view (PV:364-444):** build: the tiles laid as the game lays them in a 220-unit box (PV:334-362), Facing with < and > (they turn as LB and RB turn the cursor, PV:392-411), the game's words, Strength, Skill. Craft: What you get with the icon and name, the facts, Weight, Skill, What changes.

**Verb:** Build or Craft (PV:311-326): the drawer's own start action; it leaves the facing shown for the cursor (PV:316-322). Grayed with what it needs: the recipe, the skill, the parts in reach (PV:307-310).

**Leash:** none (no square). Closes in a vehicle (OC:272).

**Lite:** no branch.

**Pad:** oc:faceL, oc:faceR, oc:verb:go; B closes, focus back on the icon stop.

**Small screens:** the half card (PV:26), over the tab's card.

### PV 2. Against the game (steps)

| Job | Game | ZeD preview card |
| --- | --- | --- |
| See what a build looks like | The build panel's picture | The icon (1); every face, < and > (1 each) |
| Know how strong it will be | No reading | Strength, with what the skill adds |
| See what a craft upgrade changes | Compare tooltips by hand | What changes, old to new |
| Build or craft from it | The panel's button (1) | Build or Craft on the card (1), or the drawer's |

### PV 3. States to sweep

- **Build:** a wall, a fence, a gate on several squares, a barricade, a stair; a single-face thing; Carpentry 0, 3, 10; Construction Bonus Points 1 to 5.
- **Craft:** a weapon upgrade with the base carried, without; a mapper recipe; a recipe with several results; a recipe not known; skill short; parts out of reach.
- **Presses:** < and > around the full turn; Build after a turn; Build with parts gone since the last refresh.
- **Changes while open:** another recipe picked; the base item dropped; a skill level gained.
- **Layout:** 220 at 1280x800 Large text; a long recipe name; long change lines.
- **Languages:** DE, FR (Facing, Strength, the change lines).
- **Seated:** open in a car.

### PV 4. What the tests check already

| Script | What it checks |
| --- | --- |
| zedqa_preview_card (188-430) | The big metal fence: the half card, tiles, Facing with < and >, the game's words, Strength 450, Skill, the Build verb; B closes and focus returns; another pick closes it; the log fence and gate strength with carpentry; no strength on a plank barricade; a double gate's tiles; the spiked bat's What changes; "or one of N others" |
| bd_tab, cb_build_fixes_sim | B6: the cursor starts on the face the preview showed; > and < turn as RB and LB |
| rt_cards | Picking another recipe closes the preview card |

**Gaps:**
- Construction Bonus Points other than the default; a skill gained while open.
- Build or Craft from the card with the parts gone since the last refresh.
- Seated; languages but EN; Large text at 220.
- zedqa_preview_card is from Nov 1; PV changed Nov 25.

### PV 5. Suspicions (to prove in the game)

- **PV1:** The craft card is rebuilt every 250 ms. craftData runs on every refresh (PV:301): instanceItem of the output (PV:233-236), getFirstTypeRecurse over the inputs (PV:257-271) and the facts of two items, a new item each time. Prove the frame cost with the card open beside the Craft tab (perf_census).
- **PV2:** The strength's bonus is rounded (PV:117) where the game keeps the fraction (BIE:671-675): at Construction Bonus Points 1 or 2 an odd bonus reads one off the thing built.
- **PV3:** The build card's strength is worked out once (PV:298): a Carpentry level gained while it is open leaves the old number.
- **PV4:** The verb's state can be 250 ms old (PV:305-306); prove the drawer's start action refuses when a part left reach in that time.

---

## Suspicions in one list (by cost)

1. LK1: a crate locked with a code changed during the question (OC1).
2. LK2: on a server a right code reads wrong; a second Lock spends a second padlock.
3. MD1: no sign of a running treatment: a second press spends a second item.
4. PL1 / OC2: the World window's close skips onClose: the placement unsaved for others, the gizmo left.
5. TD1 / OC3: B ends a trade for both players.
6. LA1: Power pressed twice turns the machine on and off.
7. LA2: the invented cycle never ends; no clean, wet or dry reading.
8. LK4: "in your bags" where the rule is the main inventory.
9. OC4: the full card at 1280x800 leaves 88 units of inventory.
10. The rest in each card's section 5.
