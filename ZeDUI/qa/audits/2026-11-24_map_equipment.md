# Equipment tab: map for the gamut sweep (QA, Nov 24 2026)

A read-only map of ZeD's Equipment tab against the game, written before the eq_ sweep scripts. Line refs are as of 64fa2e606.
Short names: ET EquipmentTab.lua, ED EquipDoll.lua, CW ZeD_CharacterWindow.lua, ICO ItemCardOrganism.lua, IC ItemCard.lua, BELT ZeD_Belt.lua, SA ZeD_SmartAttach.lua.
FEATURE_MAP rows for this tab cite old lines (about 170 lines off).

## 1. What the tab does

**Getting there:** the tab strip (CW:856); the inventory's "Worn and held: Equipment" line when wornInList = On the Equipment tab (ContainerControls.lua:1226-1255); LB/RB on the pad; the D-pad Clothing wheel's last row "Everything you wear" (ZeD_DpadWheels.lua:1067-1072). Switching tabs clears the selection (CW:1255, 4893).

**The "Equipped" heading (ET:1911-1917):** a click or pad A on "equipslot:__disclosure" (CW:2542-2557) folds and unfolds the list and the doll. The defense block stays when folded.

**List and Doll (ED:1182-1204, click ED:1259-1280):** pad stops equipview:list and equipview:doll (CW:2563-2574). The equipView option is saved (Settings.lua:249-253, default List). Picking the view already on screen while folded does nothing (ED:1271).

**Find (TabFind.lua, ET:1922):** dims rows that don't match and hides none. It matches the name, the slot words and the parts covered (ET:1857-1864). While it holds text, the Defense block hides (ET:1689), belt rows dim and are no pad stops (ET:1871, CW:2632), empty doll slots are no stops (CW:2649) and groups with no match are no stops (CW:2588). No match shows a Clear panel (ET:1793-1796). Pad stops: equip:find and equip:findclear.

**List view (ET:1797-1874):**
- Columns: NAME, SLOT, COND, Bite, Scratch, Bullet, Wt (ET:1263-1337). Three dividers drag by mouse (CW:5799-5815, 5641-5652), held for the session only, with no pad path.
- Groups (ET:194-230), all folded at the start (CW:4807). Folded shows filled rows only; open adds "---" rows.
  - Head and face: HAT EYE MSK EAR SCF
  - Torso: OUT INR VST UND NKL
  - Arms: GLV WCH RNG ARM SHD
  - Legs: PNT SOC BOT KNE
  - Held and Belt: PRI SEC BAG BLT
- Layers: each extra worn thing in a slot gets its own row ("INR#2", ET:663-717), outermost first.
- A two-handed weapon shows in PRI only; SEC reads empty (ET:693, ED:326).
- A row (ET:968-1087) shows the icon and name, the slot words, one meter (condition, or fill for a bottle or lighter), and Bite, Scratch and Bullet as dots with no number. Bullet reads only the first part covered (ET:581-585). Wt is getUnequippedWeight. The help line reads "X: press for its card". The loot tooltip shows on hover or on pad focus (ET:318-342).
- On a narrow card (ET:502-539) the slot words shorten first, then the meter, then the columns, then Wt, then the protection columns. All of this is skipped once a column has been dragged (ET:504).
- Belt rows (ET:1131-1255):
  - Each row shows the key ("-" past 8), the icon, the name or "Empty", "Slot from <provider>", the meter, an "In hand" tag and a verb.
  - The verb is DETACH (BELT.detach), PUT BACK (BELT.activate, hb:activateSlot) or ATTACH (BELT.slotMenu, BELT:861-889).
  - Right-click opens BELT.rightMenu (CW:6077-6085). Pad A runs the verb at once (CW:2346-2352). Pad X opens the item menu or the slot list (CW:2353-2362).
  - With Held and Belt folded, only filled belt slots show.

**Doll view (ED:664-852):**
- The 3D model is rebound on OnClothingUpdated.
- 11 big slots (ED:120-148) and 38 small slots in side bands (ED:154-214). The bands show only when the drawer is at least 0.9 x 466 units wide; otherwise small things fold into their big slot as layers.
- Main hand, Off hand and the belt boxes sit below the figure. Each box shows a 5-segment condition strip and a layer plate.
- The model scales down to MIN_FIT 0.7, then the tab scrolls.
- A click on a filled box opens the card. A click or A on an empty slot does nothing (CW:2647-2657). An empty belt box opens the attach list (ED:819-831).
- The D-pad has its own moves (ED:920-1015).
- Drop onto the doll (ED.takeDrop ED:1057-1099): a garment that fits is worn with wearItem; a tool on a belt box or Back is attached. A drop while paused is swallowed (ED:1069). There is no pad path.

**The card (ET:1558-1619, ZeD_ItemCard, sourceContext "equipped"):**
- Opened by a release without moving, or by pad A (CW:2299).
- Verbs: UNEQUIP, DROP and MORE (ICO:452-458, IC:1063-1073). For clothing, also WASH, REPAIR all and PAD all (ICO:536-542).
- Per-part zones show holes, patches and blood, with dirt and wet tags (IC:690-930). The facts panel shows bite, scratch, bullet, insulation, wind and water (ItemFactsPanel.lua:79-160).
- Doll layer strip "Layer i of n" with Inner and Outer (ED:1214-1251; pad equipcard:__layer_+-1).
- Back with the arrow or B (CW:2396-2426); the focus returns to the slot (CW:2663-2675).

**Other paths:**
- Right-click or pad X on a filled row or box opens the game's item menu for it (CW:6087-6105, 2324-2345); on the doll, for the outermost layer only. Its Inspect opens the inventory card over the tab (Overrides/Garment.lua:51-98).
- A drag from a row or box becomes an inventory drag. A release inside the Equip drawer does nothing (ET:1472).

**Defense block (ET:842-940, ProtectionTab.lua:168-305):** the figure is colored by summed bite per part. It shows a grade A-F from the average bite over 18 parts including Back, the average, the worst and best zone and the garment count. Hover or pad focus "equippart:<name>" shows that part's Bite, Scratch and Bullet bars.

**Lite:** no branch in ET or ED. Lite changes only the belt HUD look and turns Smart attach off.

**Settings:** equipView, wornInList, smartAttach, contextStyle, menuGuess, Belt Lite/Full, UI scale and text size.

## 2. Against the game (steps)

| Job | Game | ZeD Equipment tab |
| --- | --- | --- |
| Wear | Double-click (1), menu Wear (2) | No path in List; a drag onto the doll (1, mouse only); none by pad |
| Take off | Double-click (1), menu (2) | Card UNEQUIP (2), menu (2), pad A A (2); no double-click on the tab |
| Swap hands | Menu (2), a drag onto a hand circle | Menu (2), card MORE (3); the doll's hand boxes take no drop |
| Attach | Menu Attach (3), hotbar radial | ATTACH (2, or 3 with the group folded), drop on a belt box (1), smart attach (0) |
| Detach | Menu (2) | DETACH (1) |
| Hood or sleeves | Menu (2) | Menu (2), card MORE (3), the pad wheel |
| Protection | The table of 17 parts, bite and scratch | Grade and summary; per part by hover (18 hovers); adds bullet |
| Wet, dirt, blood | Tooltip, Temperature tab | The card only |

## 3. States to sweep

- Every slot filled and empty in both views, and all 38 small slots with bands on and folded.
- Where the two views differ:
  - underwearbottom is Torso UND in List and Legs on the doll.
  - torsoextravest and vesttexture are VST in List and Outer on the doll.
  - gorget is VST in List and Neck on the doll.
  - shoulderholster is VST in List and holster on the doll.
  - legs5 is in neither.
- Layers (tank top under T-shirt, sweater under jacket, two rings, socks and shoes): INR#2 rows, the layer plate and the strip, UNEQUIP outer then inner.
- Broken, wet, bloody, dirty, holed and patched garments.
- Hands and bags:
  - a two-handed weapon;
  - one hand plus the off hand;
  - a lit lantern in hand;
  - a bottle or lighter;
  - a generator or corpse;
  - a bag worn vs held, a fanny pack, a backpack plus a Back weapon;
  - a watch.
- Hood up with a hat; jacket open; sleeves rolled.
- The belt: ATTACH, DETACH, PUT BACK, a slot from a worn holster (then the holster off), past 8 slots. Smart attach on and off.
- Many worn things (scroll), long names, Large text, the half card, 1280x800, the doll at MIN_FIT, a column drag then a card resize.
- Find in List and Doll, no match, Clear; paused; seated (Drop refused, ET:1364); Lite; wornInList Tab; contextStyle strip vs list; a tab switch with the card open; the folded heading with Doll.

## 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_inventory 8e (1381-1452) | the heading folds; right-click opens the menu; Find dims and Clear (List only) |
| rt_windows (439-507) | List and Doll switch and the option follows; a group folds; a divider drag |
| rt_cards (675-730) | EQUIP from the inventory card; pad A on PRI opens the full-width card; back |
| bx_inventory 10 (1716-1903) | HUD belt drags; a cap dropped on the doll is worn; a doll box drag into a crate |
| rt_strain, hg_tint | the defense figure takes no strain tint |
| lv_calls B, C, O | smart attach, the spare on break, the menu guess |
| lv_move | held and belt things stay out of Transfer all |

**Gaps:**
- UNEQUIP and DROP from the tab, by mouse and by pad.
- Belt rows: DETACH, PUT BACK, ATTACH, right-click and pad.
- Doll: card, layer strip, D-pad moves, empty slots and the attach box.
- Defense numbers against the game's getBodyPartClothingDefense.
- Dots, meters and Wt against the item.
- Narrow-card fitting.
- Every body location placed in both views.
- Hood and sleeves from the tab.
- Inspect, WASH, REPAIR and PAD.
- Find with layers.
- wornInList Tab.
- Lite.
- The pad end to end.
- Small screens.

## 5. Suspicions (to prove in the game)

- **S1:** card UNEQUIP doesn't leave the card. On a layered slot the card turns into the inner garment, and A A takes off two layers.
- **S2:** a drop on the doll calls wearItem, not onWearItems, which skips lowering a hood before a hat (ED:1083).
- **S3:** the doll's Main and Off boxes take no drop (ED:808-831).
- **S4:** PUT BACK on a held flashlight or lantern toggles the light (ISHotbar:activateSlot 549-559).
- **S5:** pad A on a belt row acts at once; on a worn row it opens a card.
- **S6:** narrow fitting is off after a column drag (ET:504), and columns can run past the edge.
- **S7:** no way to wear from the tab (List, empty doll slot, pad); no double-click to take off.
- **S8:** empty belt slots are hidden while Held and Belt is folded.
- **S9:** a two-handed weapon leaves the off hand looking free.
- **S10:** no hand verbs on an equipped card.
- **S11:** defense is summed in Lua over 18 parts with Back (no tile for Back); the Bullet dot reads one part.
- **S12:** Inspect opens a second, different card.
- **S13:** the doll card gathers every frame (speed).
- **S14:** the old _handleAction drop skips the favorite guard (ET:1365).
- **S15:** pad menus anchor from _itemDrawerPanel.
- **S16:** a drag from a doll box to a doll belt box does nothing.
- **S17:** the D-pad Clothing wheel keeps 10 rows.
- **S18:** the active view button does nothing while folded.
