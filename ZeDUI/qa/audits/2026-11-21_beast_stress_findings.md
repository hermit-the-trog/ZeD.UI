# Beast day stress scripts (Nov 21 2026, QA): bugs for Build, batch 5

Found by the 15 new stress scripts (ZeDUI/tools/qa/bx_*.lua). The six that ran first were run on a5ea25365 and
e96e2fcfc, before batches 1 and 2. Each failing line was then traced in ZeD's code by one agent and checked by a
second, skeptical one; the 7 that had not run yet were read against the game's API the same way. Every item below
was kept by both. "Seen in game" means the first run showed it; "code read" means it is not seen in game yet. The
scripts keep a check for each, so the next run shows the fix. None is touched by Build's commits 27545ddeb..f22910bc2.

## Seen in game

### B5-1 A click on a container in the world does not bring the World window's rolled-away inventory side down

- What the player meets: mouse play, the World window on a tab (Craft, for example) with its inventory side not
  pinned, so it rolls away under its rod when the pointer leaves. A left click on a crate, a fridge or a trunk in the
  world switches ZeD's hidden list to that container, but the side stays rolled up: nothing visible happens. With the
  whole window rolled up to its title bar the same click does roll it down.
- Where: 42/media/lua/client/ZeD/ZeD_WorldWindow.lua:6548-6556 (_lootPageWatchFor: only `if win.windowShaded then
  ... setWindowShaded(false) end`) and 6292-6316 (selectContainer); neither touches win._rolled / win._halves.inv.
  The section's own header (6469-6478) says the window rolls down and shows the container.
- Likely fix: after the shade branch, bring a self-rolled side down the way the bumpers and Y do (WindowHalves.lua:854
  H.showAll), keeping the _outSince hold.
- First run: "FAIL a left click on a crate with the inventory side rolled under its tab rolls the side down on that
  crate | side rolled true, its list on crate" (bx_inventory).

### B5-2 A window rolled up while its side is rolled keeps its curtain rod on screen

- What the player meets: with the inventory side rolled under its rod, a double-click on the title bar rolls the window
  up to its bar, but the rod stays beside it; drag the rolled-up bar away and the rod stays where it was.
- Where: 42/media/lua/client/ZeD/WindowCurtain.lua:114 and 428-429 (C.sync hides and moves the rod, but runs from the
  drawer's prerender, which never runs while setWindowShaded has hidden the children; the rod's own prerender at :114
  does not look at windowShaded). Callers ZeD_CharacterWindow.lua:5113, ZeD_WorldWindow.lua:4351.
- First run: "rolled up true, rod showing true" after 120 frames, on both windows (bx_windows).

### B5-3 The window box's menu stays up after its window closes

- What the player meets: pull the menu down from a window's box, then press the inventory key: both windows close and
  the menu floats on screen until a click or Escape.
- Where: 42/media/lua/client/ZeD/ZeD_WindowMenu.lua:284-298 and 82-86 (the menu holds its window but never checks it
  is still open); ZeD_ContextList.lua:570-576 and 672 (it takes only arrows, Return and Escape, so the inventory key
  reaches the game).
- First run: "the menu is still open, its window gone" (bx_windows).

### B5-4 Reset both windows (or Reset this window) leaves the World window on its tab

- What the player meets: with the World window on Maps, Craft or any tab, Reset shuts the card and moves the window
  back, but the old tab stays lit with no card, and the window does not act as on Loot (container clicks do not open
  Loot columns) until Loot is clicked. The Character window goes to Loot correctly.
- Where: 42/media/lua/client/ZeD/Organisms.lua:1562-1598 (resetWorld clears _drawerOpen and _drawerMode but not
  _activeTab; resetChar sets it at :1539/1541). Loot-only code tests win._activeTab == "loot" (ZeD_WorldWindow.lua:1200,
  2229, 2482, 3251, 4004); the strip lights win._activeTab (:2070).
- First run: "x 1929 (want 1929), y 0, tab maps" (bx_windows); the same fault showed in bx_scale's put-back.

### B5-5 List look: the heading of every world right-click menu reads "Item"

- What the player meets: Context menu set to List; right-click a door, a window, a sink, the ground or a corpse: the
  heading says "Item" instead of the thing's name (or "Floor").
- Where: 42/media/lua/client/ZeD/ContextMenuRegistry.lua:1190-1212 (Registry.getTargetDisplay; isJavaList at 1097,
  pickWorldObject at 1149). The world branch expects a Java ArrayList, but the game passes a Lua table of objects
  (vanilla ISObjectClickHandler.lua:31-63 -> ISMenuContextWorld.lua:41; ZeD stamps it in Overrides/ContextMenu.lua as
  menu._zedTarget), so it goes down the inventory branch and line 1208 answers IGUI_Item. Drawn by ZeD_ContextList.lua:346-363.
- First run: all 14 world menus (13 world things and a corpse) read "Item" (bx_context).

### B5-6 Strip look: rolling the wheel steadily through a long menu blanks the strip

- What the player meets: on a right-click strip with 11 or more actions, keep rolling the wheel with no 0.2 s pause
  (about 11 notches up or 24 down on a 15-action menu): the cells run out and the strip shows empty slots until the
  wheel rests, then it snaps back whole.
- Where: 42/media/lua/client/ZeD/ZeD_ContextMenu.lua:497-517 (next / prev move _ctx.pos with no bound and each step
  puts the settle off by animMs + 20 ms), 721-739 and 774-777 (the settle runs only in update); the track is three
  copies (237-257) and Molecules.lua:4274-4309 draws only cells that exist. page() has a guard for this (536-546).
- First run: 45 notches, one a frame, left 7 of 10 cells in the strip's box at frame 48; half a second later whole again
  (bx_context).

### B5-7 A big scale-up piles the Character and World windows on top of each other

- What the player meets: on a 4K screen at 1x (or with the windows right of center), picking 2x (worse with Large
  text) reopens both windows against the right edge, one covering the other.
- Where: 42/media/lua/client/ZeD/ZeD_CharacterWindow.lua:263-272 (applyCharState) and the World window's restore;
  42/media/lua/shared/ZeD/Scale.lua:1122-1146. Places are multiplied from the screen's top-left corner, then clamped
  on screen one window at a time.
- First run: "Large, High contrast, Lite and 2x in one frame: Character 2930,0 814x1440, World 2602,0 1238x1440" from
  Character 1428,0 444x720, World 1890,0 618x720 (bx_scale).

### B5-8 Building tab: Build never starts the placement cursor

- What the player meets: World window, Building tab, a recipe the row says he can build, Build pressed: nothing happens,
  no ghost to place, no message. The game's own build menu works for the same recipe.
- Where: 42/media/lua/client/ZeD/BuildingTab.lua:311-328 (startBuild): a fresh BuildLogic.new gets setRecipe and
  setContainers, then getSelectedBuildObject() (:325) and getWallCoveringParams() (:328). In the game's BuildLogic the
  recipe lookup is filled only by getAllBuildableRecipes(), so both throw NullPointerException ("craftRecipeComponentScript
  is null", BuildLogic.java:82 and :98) and the pcalls swallow it. ZeD's own ObjectCardPreview.lua:59-61 documents the
  trap and calls getAllBuildableRecipes() first.
- Likely fix: call logic:getAllBuildableRecipes() on the new logic before :325.
- First run: the two NullPointerExceptions in the console (ChurnBucket, the game says buildable) (bx_craft).

### B5-9 Food does not freeze, thaw or go off on screen while ZeD's lists show it

- What the player meets: a steak in a powered freezer, watched in ZeD's Loot pane, never starts to freeze; it stays at
  0 until it is moved to another container, when the game catches it up at once. By the same cause a food's Fresh,
  Stale, Rotten and Frozen state in ZeD's lists and cards can lag behind what the game's list would show.
- Where: ZeD's lists never call item:updateAge(). The game's list asks every food it draws to age
  (media/lua/client/ISUI/ISInventoryPane.lua:2273, and :2580 for shut stacks); in single player Food.update() ages food
  only on a server (javap -c zombie.inventory.types.Food), and nothing else ages food that just sits. grep updateAge
  over 42/media/lua finds nothing. Likely place: the list build in InventoryRenderer.lua near :2580 and the World
  window's container panes.
- First run: "freezer powered true, steak freezing 0", then "after 25 s: freezing 0 of 100" at 3x (bx_cook).

### B5-10 After a drag, the list keeps a pick on the thing that left it

- What the player meets: drag one thing out of a crate (or out of the bag). That list's band now reads Take marked (or
  Move marked) for a thing no longer in it, the first press moves nothing, and the help line says 1 of N picked.
- Where: each drag's press picks the row in the list it leaves, and no release handler lets go of it: the Character list
  (ZeD_CharacterWindow.lua:7261-7293 onMouseUpOutside, 7155-7170 onMouseUp) and the World list
  (ZeD_WorldWindow.lua:6033-6066 and 5979-5992); no list rebuild prunes it. The game's own list does (ISInventoryPane:
  onMouseUpOutside sets self.selected = {}, and its refresh keeps only picks it still holds), and so do ZeD's other
  moves (Take marked and Move marked call padClearMarksOf; the column XFER button empties srcCs.selectedItems at
  ZeD_WorldWindow.lua:5778-5780). The band reads the picks unfiltered (ContainerControls markedOf ->
  InventoryRenderer.padMarkedAll).
- First run: after fifty drags the crate's button read "Take marked" and moved nothing (bx_inventory).

## Code read (the scripts will show them on the next run)

### B5-11 A jammed gun looks ready everywhere in ZeD

- What the player meets: the pistol jams. The belt's ammo pouch still shows "12+1", the item card and its facts still
  show the rounds, nothing says Jammed; the trigger just clicks. Only the firearm wheel (Unjam) or the game's tooltip
  tells him.
- Where: 42/media/lua/client/ZeD/ZeD_Belt.lua (B.ammo, B.ammoWords, B.ammoLines), ItemFactsPanel.lua (M.CombatFacts),
  ItemCard.lua (ZeD.itemFacts). No isJammed anywhere in client/ZeD or shared/ZeD.

### B5-12 An animal's page stays open on an animal that has left the world

- What the player meets: with an animal's page open in the Animals tab, the animal dies, is picked up or butchered: the
  page stays up with the old animal's numbers and buttons instead of stepping back or saying it is gone.
- Where: 42/media/lua/client/ZeD/AnimalsTab.lua renderRanchAnimal (about :3072) shows "animal gone" only when
  animalRef is nil, and nothing sets it to nil when the animal leaves the world (cleared only at :281, :284 and :313:
  Back and the sub-tab switch). WorldRoutes.animalLeft covers only an animal with no zone opened through the game's Info.

## Watching (not for Build yet)

- Some UI scale steps kept the windows' old pixel size on the old code (Auto 2x -> 1.75x, 1.5x -> 1x; 6 of 8 steps
  were right). 1cea31b69 (W36) changed that path and may have cured it; bx_scale's new height check will tell.
