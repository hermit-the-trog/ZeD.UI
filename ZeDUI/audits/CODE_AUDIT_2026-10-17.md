# ZeD-UI code-health audit (2026-10-17)

## How this audit was done

- **Scope:** every Lua file under `42/media/lua` (135 files, about 98,000 lines before the cleanup).
- **Method:** a static audit. Nothing ran in the game. I used three tools:
  - The game's own Kahlua compiler (`KCheck` against `projectzomboid.jar`). It parsed every file before and after the fixes.
  - A scope-aware Lua 5.1 pass over every file, which found globals, unused locals, shadowing and undefined names.
  - Targeted greps.
- **Manual review:** the per-frame paths (prerender, render, update and OnTick) were read by hand in three groups:
  - the HUD and input
  - world objects, cards and the World window
  - the Character window and its tabs
- **Line numbers** are as they stand on this branch, after the cleanup commits.

## What was committed on this branch

These are the only changes, and none of them changes behaviour.

1. **Dead local functions removed.** About 1,490 lines of code that nothing called anywhere in the repo:
   - JournalTab's old embedded map panel. The Maps tab lives in MapsTab.lua and has its own copies.
   - EquipmentTab's legacy card mode and its body-figure helpers.
   - FocusManager's retired cone picker (ZeD.SpatialNav picks now).
   - Assorted single helpers in AnimalsTab, ItemCard, IdentityTab, InventoryRenderer, ItemFactsPanel, RadioTab, ZeD_Belt, ZeD_Prompt and both windows.
2. **Unused locals and constants removed** (about 150 lines). Only where the initializer was a plain value, a table field or a pure measurement. Where only some names in a multi-name local were unused, just those names were dropped.
3. **Middle dots.** The last two U+00B7 characters, both in Molecules.lua layout comments, are now " | ". No UI string had one.

Nothing else was committed. **Accidental globals:** none were found, so there was nothing to make `local` (every global set is a deliberate `ZeD_*` class table or a hook on a vanilla global). **Debug prints:** none fire unconditionally every frame, so there was nothing to remove. The per-frame prints are error handlers; see section 5.

## Summary

| Category | Findings |
|---|---|
| 1. Scaling | 8 |
| 2. Per-frame safety, error spam and per-frame cost | 16 |
| 3. Globals, dead code, unused locals, shadowing | 9 (plus the committed removals) |
| 4. Duplicated helpers | 9 groups |
| 5. House rules (separators, button case, prints, labels) | 6 |
| 6. Kahlua pitfalls | 2 |

## The 10 most important findings

1. **A failing tab draws nothing, logs every frame, and leaves the clip rectangle set.**
   - Where: `ZeD_CharacterWindow.lua:3940` and `ZeD_WorldWindow.lua:3424` call the tab renderer with no pcall, between `setStencilRect` and `clearStencilRect`.
   - Effect: if any tab throws, the error repeats every frame and the stencil is never cleared.
   - Fix: wrap the renderer in pcall, clear the stencil on failure, and log once per (tab, message). See 2.1.
2. **Neither window lets go of the dead player.**
   - Where: nothing hooks OnPlayerDeath or OnCreatePlayer. `win._playerObj` and `content._playerObj` keep the dead IsoPlayer (`ZeD_CharacterWindow.lua:3072/4797`, `ZeD_WorldWindow.lua:2756/3092`), and the Identity 3D model stays bound to it.
   - Effect: transfers and timed actions are queued against a dead character, and after a respawn the open windows never rebind. Vanilla destroys its inventory pages on death.
   - See 2.2.
3. **The Equipment item card keeps drawing over other tabs.**
   - Where: `EquipmentTab.lua:1000`. Only the Equip tab's own render hides `panel._equipCard`.
   - Effect: after a tab switch the card stays visible and keeps eating clicks.
   - See 2.3.
4. **A failed ZeD context menu is rebuilt and logged every frame.**
   - Where: `Overrides/ContextMenu.lua:325-331`. On failure the code resets `_zedSpawned = false`, so the next prerender tries again.
   - See 2.4.
5. **Several ZeD classes still draw 1-screen-pixel borders at 4K.**
   - Where: `Overrides/TextScale.lua:83`. `ZED_CLASSES` lists only the classes that derive from the ZeD organisms. Classes that derive straight from ISPanel or ISUIElement are not flagged:
     - ZeD_ObjectCard
     - ZeD_FurnitureChip
     - ZeD_CarRadio
     - ZeD_SirenController
     - the main-menu desk, bar, drop, glass, wake, icon and key-catcher panels
     - MapsTab's ZeD_WorldMap
   - Effect: their outlines stay hairline next to 2 px dividers and buttons. The farm plot's double frame splits into two lines with a gap.
   - See 1.1.
6. **Per-frame error handlers print the same line every frame.**
   - Where: about a dozen sites (FurnitureTab, InventoryRenderer, ObjectCards, both windows, the wheels, the rod and the sleep clock).
   - Effect: one bad texture or nil field floods console.txt.
   - Fix: one shared log-once helper. See 5.3.
7. **The gamepad Show toggle in Journal > Recipes reaches a mode the Journal does not have.**
   - Where: `CraftingCore.lua:2617`. `CC.cycleShow(state, config)` names an undefined global `config` (it is not a parameter of `CC.buildFocusables`).
   - Effect: the cycle includes "Ready", which the read-only Journal list does not offer.
   - See 3.1.
8. **Dragging an item off the belt into the World window list fails while the Character window is closed.**
   - Where: `ZeD_Belt.lua:1006`. `ipairs({ cw, ww })` stops at the nil `cw`.
   - See 6.1.
9. **The belt's "prefer the equipped light" branch never runs.**
   - Where: `ZeD_Belt.lua:472`. It calls `isEquippedOrAttached`, which is a local in vanilla's ISDPadWheels.lua, so here it is always a nil global.
   - See 3.2.
10. **The item card stays open after its item is gone.**
    - Where: in the Character window, `updateDrawer` runs only when the selection changes.
    - Effect: an eaten, dropped or transferred item keeps its card and live verbs.
    - See 2.5.

---

## 1. Scaling

The UI draws in design units, which `T.px(n)` (or the pre-scaled tokens) turn into screen pixels. Anything that bypasses `T.px` stays the same size at 4K, where the root scale is 2. The plate pixel-art files (DashPx, ZeD_Plate, PhysPx, PixelParts, ZeD_TabPx, Overrides/Fishing, Overrides/Sleeping) were excluded as asked. The 1-screen-pixel rows used to rasterize the status dots, the ring and the scroll arrows in `Atoms.lua` (455-490, 636-662) are intentional and fine.

### 1.1 Borders that do not scale (medium)

- **Where:** `Overrides/TextScale.lua:83-85`.
- **Why:** the drawRectBorder patch draws `T.px(1)`-thick borders only for classes flagged `zedScaled`. A class inherits the flag only if it derives from a listed class.
- **Not covered today:**
  - `ZeD_ObjectCard` (ObjectCards.lua:679, about 8 bordered parts: tags, meters, the icon frame at 793, the warning box, the LCD and plate edges, the farm cells at ObjectCardFarm.lua:387-398 and 448-449)
  - `ZeD_FurnitureChip` (FurnitureTab.lua:776, border at 830)
  - `ZeD_CarRadio`
  - `ZeD_SirenController`
  - `ZeD_MMDesk`, `ZeD_MMBar`, `ZeD_MMDrop`, `ZeD_MMWake`, `ZeD_MMGlass` (ZeD_MainMenu.lua, borders at 881, 1232, 1426, 1804, 1813)
  - `ZeD_MMIcons`, `ZeD_MMKeyCatcher`
  - MapsTab's local `ZeD_WorldMap`
- **Suggested change:** add `"ZeD_ObjectCard", "ZeD_FurnitureChip", "ZeD_CarRadio", "ZeD_SirenController", "ZeD_MMDesk", "ZeD_MMBar", "ZeD_MMDrop", "ZeD_MMGlass", "ZeD_MMIcons"` to `ZED_CLASSES`. For the local `ZeD_WorldMap`, set `ZeD_WorldMap.zedScaled = true` after its derive.
- **Check in game:** the main-menu glass and wake panels at both 1080p and 4K.

### 1.2 High-contrast double ring insets by 1 screen pixel (medium, HC theme only)

- **Where:**
  - `Atoms.lua:116`, `Atoms.lua:237`, `Atoms.lua:685`
  - `ZeD_Panel.lua:70`
  - `ObjectCards.lua:602` (the LCD's second bezel line)
- **Why:** these draw a second `drawRectBorder` at `x + 1, y + 1, w - 2, h - 2`. Their "TODO scale?" comments say a T.px inset would open a gap "until borders scale", but zedScaled borders do scale now. At root 2 the outer ring is 2 px and the inner one starts 1 px in, so the two overlap into a 3 px band instead of a 4 px one.
- **Suggested change:** pick the inset from the same thickness the border patch uses: `local t = (panel.zedScaled and T.px(1)) or 1` and draw `panel:drawRectBorder(x + t, y + t, w - 2 * t, h - 2 * t, ...)`. For `ObjectCards.lua:602` use `T.px(1)` once 1.1 flags ZeD_ObjectCard. Drop the stale TODO comments.
- **Also stale:** `ItemCard.lua:1480` says "drawRectBorder lines stay 1 px". ZeD_ItemCard is flagged, so they don't.

### 1.3 Hairline rules and 1-2 px nudges in the readers (low)

These draw as 1 px at 4K where everything around them is 2 px.

- **`ZeD_Reader.lua`:**
  - 165 `setStencilRect(c.x + 1, c.y + 1, c.w - 2, c.h - 2)`
  - 183 the `+ 40` pan margin
  - 246 `px + pad + 1`
  - 266-269 the `-1/+1/-2`
  - 281 and 337 1 px rules
  - 306 `y + 2`
  - 370 and 836 `drawRect(1, st.y, st.w - 2, ...)`, an inset for a border that is 2 px at 4K
  - 737, 738 and 744 `r.x + 1`, `r.w - 2`, `rh - 1`
  - 785 and 800 1 px ruled lines
- **`ZeD_JournalReaders.lua`:** 352 the `drawRect(x, y + hh, w, 1, ...)` divider, 390 `x + 1`, 604 the ruled line (`- 1` and height `1`).
- **`ZeD_WorkshopText.lua`:** 244 faux bold `cx + 1`, 246 underline (`fh - 1` and height 1), 247 strike-through.
- **Suggested change:** wrap each literal: `T.px(1)`, `T.px(2)`, `T.px(40)`. For example `self:drawRect(x, y + h, w, T.px(1), ...)` and `self:setStencilRect(c.x + T.px(1), c.y + T.px(1), c.w - T.px(2), c.h - T.px(2))`.

### 1.4 Controller context-menu clearance is a raw number (low-medium)

- **Where:** `ZeD_ContextMenu.lua:871`, `local moodleAllowance = 140`.
- **Why:** what sits at the bottom of the screen now is ZeD's belt and the ZeD bottom moodle row, and both scale. At 4K, 140 px is about the belt alone, so a pad-opened menu can overlap a bottom moodle row.
- **Suggested change:** `local moodleAllowance = T.px(140)`, or better, measure from `ZeD.Belt.getHUD():getY()` when the belt is drawn.

### 1.5 Object card LED rim (low)

- **Where:** `ObjectCards.lua:615`, `UI.disc(card, x + r, y + r, r + 1, HW.ledRim)`.
- **Suggested change:** `r + T.px(1)`.

### 1.6 Identity 3D portrait is created with a nil size (low)

- **Where:** `ZeD_CharacterWindow.lua:3586`, `ISUI3DModel:new(0, 0, PHOTO_SIZE, PHOTO_SIZE)`.
- **Why:** `PHOTO_SIZE` is a local of IdentityTab.lua, so here it is a nil global, and `instantiate` calls `setWidth(nil)`. The model is resized every frame afterwards, so this only works by luck.
- **Suggested change:** `ISUI3DModel:new(0, 0, T.px(120), T.px(120))`, or export `ZeD.IdentityTab.PHOTO_SIZE` and use `T.px(ZeD.IdentityTab.PHOTO_SIZE)`.

### 1.7 Prompt buttons are measured on capitals but drawn in sentence case (low)

- **Where:** `ZeD_Prompt.lua:626` measures `tw(T.fontF3, upper(b.title))`, and line 1093 passes `upper(b.title)` to `drawButton`, which then applies `ZeD.btnCase`.
- **Effect:** buttons come out wider than their label.
- **Suggested change:** `tw(T.fontF3, ZeD.btnCase(b.title))` at 626, and pass `b.title` at 1093.

### 1.8 Item tooltip joypad offset (low)

- **Where:** `Overrides/Tooltip.lua:142-143` and `254-255`, `getPlayerScreenLeft(playerNum) + 60`.
- **Why:** this copies vanilla, and the Java item tooltip keeps the engine size, so it is only cosmetic.
- **Suggested change:** `T.px(60)` if the frame should track the ZeD root. Otherwise leave it.

---

## 2. Per-frame safety, error spam and per-frame cost

Overall the per-frame code is well protected. Item reads go through `safeGet` or `pcall`, data gathering is throttled, and nil players are gated. There is no case where a vanilla call on a nil object errors every frame in normal play. The risks are lifecycle gaps, missing error de-duplication, and avoidable per-frame work.

### 2.1 Tab renderers run unprotected inside a stencil (medium-high)

- **Where:** `ZeD_CharacterWindow.lua:3940` and `ZeD_WorldWindow.lua:3424`, `renderer(self, win, 0, 0, targetW, dh)`.
- **Why:** only FurnitureTab protects itself. MechanicsTab (vehicle, trailer and animal-card Java calls), Crafting, Building, Maps, Foraging, Radio, Animals and the Character tabs are bare. An error skips `clearStencilRect` and repeats every frame.
- **Suggested change:**

  ```lua
  local ok, err = pcall(renderer, self, win, 0, 0, targetW, dh)
  if not ok then
      self:clearStencilRect()
      local k = tostring(win._activeTab) .. tostring(err)
      if win._tabErr ~= k then win._tabErr = k; print("[ZeD] tab " .. tostring(win._activeTab) .. " render failed: " .. tostring(err)) end
  end
  ```

### 2.2 Windows keep the dead player (medium-high)

- **Where:**
  - `ZeD_CharacterWindow.lua` (3072, 4797; Identity model binding 3869-3871)
  - `ZeD_WorldWindow.lua` (2756, 3092)
- **Why:** there is no OnPlayerDeath or OnCreatePlayer handler. The World window's 30-frame container scan, the Vehicle tab and ContainerControls keep using the dead IsoPlayer. After a respawn, `ensureBothOpenForGamepad` (CharacterWindow 5698) sees the windows as open and never rebinds them.
- **Suggested change:** add `Events.OnPlayerDeath.Add(function(p) local w = ZeD_CharacterWindow.getWindow(); if w and w._playerObj == p then w:close() end; local ww = ZeD_WorldWindow.getWindow(); if ww and ww._playerObj == p then ww:close() end end)`. As a backstop, add `if self._playerObj:isDead() then return end` at the top of each `content._onPrerender`. Clear `_characterBound` on the Identity model when the window reopens.

### 2.3 The Equipment item card stays visible on other tabs (medium)

- **Where:** `EquipmentTab.lua:973-1000`. The card is a child of the drawer, and only `ZeD.EquipmentTab.render` hides it.
- **Suggested change:** in the drawer's `_onPrerender` before the renderer dispatch (`ZeD_CharacterWindow.lua:~3936`), add `if self._equipCard and not (win._activeTab == "equip" and win._drawerMode == "tab" and win._equipSelected and effectiveW > 0) then self._equipCard:setVisible(false) end`.

### 2.4 The context-menu fallback retries every frame (medium)

- **Where:** `Overrides/ContextMenu.lua:325-331`.
- **Suggested change:**
  - In the failure branch, keep `self._zedSpawned = true`, set `self._zedFailed = true`, print once, then `return origPrerender(self)`.
  - At the top of `ISContextMenu:prerender` (after the submenu check), add `if self._zedFailed then return origPrerender(self) end`.
  - In `render` (342), use `if self._zedSpawned and not self._zedFailed and not self:isEmpty() then return end`.
  - In `clear()` (246), add `self._zedFailed = false`.

### 2.5 The item card outlives its item (medium)

- **Where:** in the Character window, `updateDrawer` (4425) runs only when the selection changes.
- **Suggested change:** in `content._onPrerender`, if `win._drawerItem` is no longer in the player's inventory tree (`local c = di:getContainer(); if not (c and (c == p:getInventory() or c:isInCharacterInventory(p))) then ... end`), drop it from the selection and call `win._updateDrawer(self)`.

### 2.6 Object-card per-kind callbacks are called bare from prerender (medium)

- **Where:** `ObjectCards.lua:163` (`def.valid(t)`), `794` (`def.icon(t)`), `815` (`def.pill(t)`) and `818` (`def.title(t)`).
- **Example:** the Farm `def.icon` (ObjectCardFarm.lua:322) calls vanilla `farming_vegetableconf.getSpriteName` every frame, and that throws if a synced plant field is nil.
- **Suggested change:**
  - In prerender: `local okT, alive = pcall(OC.tick, e, player); if not (okT and alive) then self:close(); return end`.
  - Add a small `try(f, ...)` that pcalls and returns nil on failure, and use it for icon, pill and title (`try(def.title, t) or "?"`).
  - Compute the farm icon once in `def.refresh`.

### 2.7 The seat chooser checks only distance (medium-low)

- **Where:** `ZeD_SeatChooser.lua:563`.
- **Why:** if the vehicle is removed or the character dies, `readSeats()` keeps calling vehicle methods every frame.
- **Suggested change:** at the top of `update`, `if not (self.vehicle and self.vehicle:getSquare()) or self.character:isDead() then self:close(); return end`. Also wrap `self:readSeats()` in pcall in prerender.

### 2.8 The dashboard hides without releasing gamepad focus (medium-low, edge case)

- **Where:** `ZeD_Dashboard.lua:460`.
- **Why:** if the car is lost by a path other than OnExitVehicle, an invisible dash keeps focus and live elements.
- **Suggested change:** `self:setVisible(false); self.vehicle = nil; self._driver = false; self:_release(); self:_unregister(); return`.

### 2.9 Watch and dash plate draws are not protected (low-medium)

- **Where:** `ZeD_Watch.lua:326` and `348`, `PLT.draw(self:_canvas(k), des, st, ctx)`.
- **Why:** `W.register` is a public add-on API, and bad add-on data would throw every frame on an always-visible prop.
- **Suggested change:** pcall it, log once per plate, and return. `ZeD_Dashboard.lua:492` (`PL.draw`) is the same pattern, at lower risk.

### 2.10 The belt tooltip keeps the first character (low)

- **Where:** `ZeD_Belt.lua:951`. `setCharacter` runs only when the tooltip is created, and the belt survives a respawn within the session.
- **Suggested change:** in the existing-tooltip branch, `local p = self:player(); if self._tipChr ~= p then self._tip:setCharacter(p); self._tipChr = p end`.

### 2.11 The title-bar weight reads the wrong container (low)

- **Where:** `ZeD_CharacterWindow.lua:4842`.
- **Why:** `ISInventoryPage.loadWeight(self._inventory)` is last frame's viewed container (a bag, or the last multi-container column), but it is divided by the player's max weight.
- **Suggested change:** `local weight = round(self._playerObj:getInventory():getCapacityWeight(), 2)`.

### 2.12 `UI.warn` draws its paragraph twice (low)

- **Where:** `ObjectCards.lua:433` and `438`. The first `UI.para` call, used only to measure, also draws, and then the tint and the text go over it again.
- **Suggested change:** measure with `ZeD.Atoms.wrapText(text, T.fontF2, w - pad * 2 - T.px(14))` and `#lines * (ZeD.TM:getFontHeight(T.fontF2) + T.px(2))`, and keep only the second `UI.para`.

### 2.13 Gamepad axis reads have no default (low, low confidence)

- **Where:** `Input/InputModeDetector.lua:130-136` and `147` do arithmetic on `getControllerAxisValue(...)`. FocusManager.lua:1286 guards the same call with `or 0`.
- **Suggested change:** add `or 0` to each read.

### 2.14 Focus lists rebuilt every frame (medium perf)

- **Where:**
  - `ZeD_WorldWindow.lua:4002-4019` (multi-container columns)
  - `ZeD_WorldWindow.lua:4043` (tab content, built before its dirty check)
  - `ZeD_WorldWindow.lua:4207-4232` (item card)
  - `ZeD_CharacterWindow.lua:5047-5064` (multi-container columns)
  - `ZeD_CharacterWindow.lua:5091` (tab content: on Journal > Recipes, one table and two closures for each of about 1,200 recipe rows, every frame)
- **Why:** these run in mouse mode too. The scroll-key gate only skips `setRingZoneElements`; the lists are still built every frame.
- **Suggested change:** compute the scroll or dirty key first and call the builder only when it changes, the same way `charMainInv` and `worldMainInv` already do. Gate on gamepad mode or the focused window. Hoist the per-element handlers (they only use `w, el`) to module level.

### 2.15 Other per-frame work worth caching (low-medium perf)

- **MechanicsTab.lua:**
  - 1460 and 1595 call `fixRows(part, chr)` twice a frame, uncached, through the FixingManager inventory scans. Cache it for 300 ms the way `needsFor` is.
  - 1043 (also 955 and 990) rebuilds `collectParts(v, chr)` every frame. Cache it by `v:getId()` for about 250 ms.
- **ObjectCardFarm.lua:427 and 493** (also 149/152): `getLuaObjectOnSquare` runs twice per plot per frame for up to 13x13 plots, and each call copies modData. Store `t.plant` in `def.nearby` and read it back.
- **Object-card refresh scans every 15 frames:** Fire `getNearbyFuelInfo`, Farm `seedRows`, Trough `getAllEvalRecurse`, Power `petrolCans`, Fluid `carried`. Make `OC.REFRESH` (ObjectCards.lua:36) time-based, about 500 ms.
- **CraftingTab.lua:291-298** creates a new `HandcraftLogic` every frame while a batchable recipe is selected. Throttle it to once a second.
- **ForagingTab.lua:1073-1083:** radius, categories, focus options and trait modifiers are recomputed every frame. Use a 15-30 frame cache.
- **HealthTab.lua:570-577, 607, 632:** seven recursive `isExerciseAvailable` inventory checks per frame. Move them into `gatherData`, which is already cached.
- **JournalTab.lua:594:** `_measureJournalContent` re-wraps every entry every frame. Cache the result by entry count, width, collapsed groups and `T.scale`.
- **ZeD_CharacterWindow.lua:2598-2613:** the container strip re-sorts every frame in WT and TYPE modes. Sort only on the 30-frame refresh or when the mode changes.
- **InventoryRenderer.lua:401, 404 and 874:** pcall closures per item per frame around plain methods (`isEquipped`, `getAttachedSlot`). Call them directly.
- **Dashboard:** `_state` (ZeD_Dashboard.lua:144-190), `RO.read` (ZeD_RadioOps.lua:102-147) and `_badges` (480) build dozens of closures every frame, and the radio is read twice a frame when the car-radio prop is up. Cache the badge per vehicle id and throttle the radio read to about 100 ms.
- **Belt while dragging (ZeD_Belt.lua:880, 900-903, 921):** `_dropState` pcalls `B.fits` for every dragged item on every slot every frame. Compute it once per drag, one item per full type.
- **ItemActionHooks.lua:170 and 194-236:** while reading, the probe list is allocated and the inventory scanned every tick. Remember the found book.
- **Overrides/PostDeath.lua:258:** `recordRows` re-wraps every frame. Cache it by `(rec, innerW)`.

### 2.16 Cleared

Checked and properly guarded:

- **HUD props:** ZeD_Dashboard, ZeD_Watch, ZeD_CarRadio, ZeD_SirenController and ZeD_Moodles prerenders. ZeD_BeltHUD prerender and visibilityTick, via `wanted()`.
- **Context menus and wheels:** ZeD_ContextMenu prerender, ZeD_Wheel and Overrides/Wheels update.
- **OnTick handlers:**
  - ZeD_RadioOps scanTick
  - KillTracker onTick
  - Stations watchdog
  - BumperChord and FocusManager ticks (the aim print is edge-latched)
  - InputModeDetector pollMouseButtons
  - ItemActionHooks ticks
  - the self-removing retry ticks (Overrides/Stations, Overrides/WorldMap, ZeD_QuickWheel)
- **Overrides:** the Tooltip, Belt, PostDeath, Fishing and Sleeping overrides.
- **Object cards:** every object-card `def.valid`; `OC.tick` (refresh in pcall, leash, vehicle and death checks).
- **Station and vehicle views:** StationMachine and StationAppliance (all Java behind pcall). MechanicsTab.render (vehicle square check, caches). MechTrailer (caches, animal-left close). FurnitureTab render and chip. ContainerControls refresh (de-duplicated).
- **Character window and tabs:**
  - every ZeD_ItemCard path
  - ItemCardOrganism and ItemFactsPanel
  - EquipmentTab, Health, Thermal, Identity, Skills, Protection, Journal, Radio, Maps and Animals data paths
  - CraftingCore render, scan and containers
  - ZeD_JournalReaders gather and ZeD_Reader update (closes on death)

---

## 3. Globals, dead code, unused locals, shadowing

### 3.1 Undefined `config` in the gamepad Show toggle (medium)

- **Where:** `CraftingCore.lua:2617`, `CC.cycleShow(state, config)` inside `CC.buildFocusables(win, state, prefix, pinKey, startAction)`. `config` is a nil global.
- **Effect:** in Journal > Recipes (read-only), pad A on Show cycles Ready, Known, All instead of Known and All.
- **Suggested change:** `CC.cycleShow(state, { readOnly = (prefix == "jrecipe") })`, or add a `config` parameter and pass `_jrecipeConfig` and `craftConfig` from the callers (ZeD_CharacterWindow.lua:2160, ZeD_WorldWindow.lua:813/822, CraftingTab.lua:524).

### 3.2 `isEquippedOrAttached` is not reachable (low-medium)

- **Where:** `ZeD_Belt.lua:472`.
- **Why:** vanilla declares it `local` in ISDPadWheels.lua, so the guarded call is always skipped, and the light list never prefers the equipped light.
- **Suggested change:** `if playerObj:isEquipped(item) or (hb and hb:isItemAttached(item)) then`.

### 3.3 Other undefined names (low)

- `Molecules.lua:4011`: `bg = T.surf3 or bg`. `bg` is a nil global, so the fallback is dead. Use `T.surf3 or T.surf1`.
- `ZeD_CharacterWindow.lua:3586`: `PHOTO_SIZE`. See 1.6.

### 3.4 Accidental globals

None. Every global assignment is one of these:

- a deliberate class table (`ZeD`, the `ZeD_*` derives, `ZeDOpenCardAction`, `ZeD_HookBridge`)
- a deliberate wrap of a vanilla or Java global: `forceChangeState` (ZeD_MainMenu.lua:465), `namedColorToTable` (Overrides/MainMenu.lua:43), `getTextManager` (shared/ZeD/Scale.lua:279)

### 3.5 Flyers sub-tab remnants

`_flyerOpenIdx`, `_flyerClickZones`, `renderFlyers` and `buildFlyerCatalog` are already gone.

What remains is `win._flyerSearch` and `win._flyerSearchText` (ZeD_CharacterWindow.lua:3569-3578, ZeD_JournalReaders.lua:241/528, JournalTab.lua:521). These are live: they are the search field for the Notebooks and Papers shelves (`JR.searchVisible`, ZeD_JournalReaders.lua:727). Two suggestions:

- Rename them to `_shelfSearch` / `_shelfSearchText`.
- Fix the placeholder (see 5.4).

### 3.6 Parked dead code left in place on purpose

- **Where:** `_buildJournalSaveFocusable` (ZeD_CharacterWindow.lua:2067) and `_buildJournalDeleteFocusables` (2117).
- **Why left:** nothing calls them, and the comment at 2140 says they were left out because the old cone picker rejected the sideways hop, with delete "deferred to future polish". The free-nav picker no longer has that limit.
- **Decision needed:** wire them into the journal focusables or delete them.

### 3.7 Unused locals left in place

Their initializers call something, so removing them could change behaviour:

- `AnimalsTab.lua:732/754` (`w, h` of `getZoneDimensions`); 2117, 2731 and 2949 (`ad = AD()`)
- `BuildingTab.lua:58` (`okEl` pcall), 250 (`containers = CC.gatherDetail(...)`)
- `ZeD_CharacterWindow.lua:3134` (`mcColumnEls = _buildCharacterMCColumnFocusables(win)`, built at window open and never used)
- the `colIdx` / `hdrColIdx` / `catColIdx` / `stkColIdx` halves of `getColumnAtX` pairs (CharacterWindow 5286/5310/5325/5566, WorldWindow 4442/4466/4479/4713/4741)
- `ZeD_Dashboard.lua:466` (`w, h` of `_layout()`)
- `ZeD_Belt.lua:921` (`it` of `_dropState`)
- `SkillsTab.lua:895` (`tmActualH`)
- `ZeD_MainMenuLooks.lua:379` (`v = looks()`)
- `ZeD_MainMenuOptions.lua:221` (`o = mo()`), 751 (`ctx = self:pctx()`)
- `ZeD_MainMenuSaves.lua:717` (`okM` pcall)
- `ZeD_Prompt.lua:1038`
- `FurnitureTab.lua:365` (`f2`)
- `MapsTab.lua:1039` and `Overrides/Tooltip.lua:109` (`err` of pcall)

Assigned but never read: `ItemActionHooks.lua:169` (`probeName`), `JournalTab.lua:120` (`_jRecipeByName`), `ZeD_MainMenuMods.lua:1380` (`src`).

For each, either use the value or replace `local x = f()` with a bare `f()`.

### 3.8 Redefinitions and shadowing (low)

- **Same-scope redefinitions:**
  - `AnimalsTab.lua:2223` `player` (first at 2124)
  - `EquipmentTab.lua:467-468` `dotSz` / `dotGap` (first at 455-456)
  - `ItemCardOrganism.lua:1058` `T` (1044)
  - `ZeD_CharacterWindow.lua:3509` `T` (3016)
  - Delete the second declaration.
- **Shadowing:** 34 inner `local T = ZeD.T` re-reads in the two windows (harmless; they pick up a live theme). Plus about 40 other shadowed names, mostly `bodyH`, `screenW`, `invW`, `R`, `md`, `mcSel`, `playerObj` and `playerNum` re-fetched inside closures in the two windows. None are wrong today, but `playerObj` (CharacterWindow 4405, WorldWindow 4289) and `playerNum` (CharacterWindow 5610, WorldWindow 4290/4783) are worth a rename to make the closure's own lookup obvious.

### 3.9 Stale comments after the cleanup (low)

- `EquipmentTab.lua:893-896` (the "ACTION HANDLER" header) still says the buttons are drawn "by _drawBackBar", which is now removed.
- `ZeD_CharacterWindow.lua:3345` still resets `win._equipBodyFigure`, which nothing creates any more. Delete the line.

---

## 4. Duplicated helpers

Report only; no consolidation was done. The shared library has `ZeD.Atoms.safeGet`, `ZeD.Atoms.wrapText` and `ZeD.Atoms.truncateText`, but no `inRect`, `sound`, `fh` or `tw`. Each group below is a candidate for a single shared version.

1. **`inRect`** (identical one-liner) in 8 files:
   - Overrides/PostDeath.lua:156
   - ZeD_CarRadio.lua:60
   - ZeD_JournalReaders.lua:54
   - ZeD_Keyboard.lua:35
   - ZeD_Prompt.lua:61
   - ZeD_Reader.lua:47
   - ZeD_SeatChooser.lua:60
   - ZeD_SirenController.lua:43

   Add `ZeD.Atoms.inRect`.
2. **`sound`** in 7 files: ZeD_CarRadio.lua:59, ZeD_JournalReaders.lua:55, ZeD_Keyboard.lua:36, ZeD_Prompt.lua:62, ZeD_Reader.lua:48, ZeD_SeatChooser.lua:61 and ZeD_SirenController.lua:44. The default sound differs: none, "UIActivateButton" or "UISelectListItem". Add `ZeD.Atoms.uiSound(name, default)` using `pcall(sm.playUISound, sm, name)` so it builds no closure.
3. **`fh` and `tw`** in 5 files: Overrides/PostDeath.lua:154-155, ZeD_JournalReaders.lua:52-53, ZeD_Prompt.lua:58-59, ZeD_Reader.lua:45-46 and ZeD_SeatChooser.lua:58-59.
4. **Text truncation**, three identical binary-search truncators:
   - `ZeD.Atoms.truncateText` (Atoms.lua:1023)
   - `CC.truncText` (CraftingCore.lua:359, with 36 callers)
   - a local `truncText` (SkillsTab.lua:398)

   Point `CC.truncText` at `ZeD.Atoms.truncateText`. The Atoms version also handles `maxW <= 0`.
5. **`call(o, m, ...)`** (safe method call) in FurnitureTab.lua:55 (already forwards to ObjectCards), MechTrailer.lua:72, ObjectCards.lua:42, Stations.lua:39 and ZeD_Belt.lua:269.
6. **`_safe(fn, default)`** in ZeD_Dashboard.lua:142, ZeD_QuickWheel.lua:36, ZeD_RadioOps.lua:37 and Overrides/Garment.lua:28. `ZeD_Watch.lua:57` is subtly different: it returns a nil result instead of the default, so keep that difference if these are merged.
7. **`clamp`** in ZeD_Keyboard.lua:34, ZeD_Prompt.lua:60 and ZeD_RadioOps.lua:39 (ZeD_TabPx.lua:38 is a different 0-1 clamp).
8. **`getColumnAtX(content, x)`** in InventoryRenderer.lua:1435, ZeD_CharacterWindow.lua:254 and ZeD_WorldWindow.lua:1734. Export the InventoryRenderer one.
9. **Main menu and plate helpers:**
   - `comboText` in five main-menu files (Host:30, Looks:42, Options:243, Sandbox:44, Server:45)
   - `jlist` in ZeD_MainMenuMods.lua:60, ZeD_MainMenuWorkshop.lua:35 and ZeD_ModScan.lua:57
   - `plateTex` in ObjectCardFire.lua:382, ObjectCardPower.lua:222, StationAppliance.lua:476, ZeD_CarRadio.lua:57 and ZeD_SirenController.lua:42
   - the column-header click and drag handlers duplicated between the Character and World windows (CharacterWindow ~5280-5570, WorldWindow ~4440-4750)

---

## 5. House rules

### 5.1 Middle dots

- **Fixed:** the only two were in comments (Molecules.lua:3064 and 3281) and are now " | ". No UI string uses U+00B7, U+2022 or similar.
- **Inconsistency:** the separator constants differ. `OC.DOT`, `FurnitureTab`, `MechanicsTab`, `MechTrailer` and `ZeD_Belt` use `"|"` (spaces added at each use), while `EquipmentTab.lua:703` uses `" | "`. Worth one shared `ZeD.SEP = " | "`.

### 5.2 Button case

- `ZeD.Molecules.drawButton` applies `ZeD.btnCase`, and so do the other hand-built buttons (AnimalsTab drawBtn, `drawPillButton`, ObjectCards `UI.button`, the verb strips, the craft action strip).
- **Not routed through it:**
  - `Overrides/PostDeath.lua:194` (`zedButton`) draws its label raw. The labels are written in sentence case today ("Restart", "Main menu", "Shut down", "Cancel"), so it reads right. Wrap with `ZeD.btnCase(label)` (and measure the same string) so a future caps label can't slip through.
  - `ZeD_Reader.lua:359` passes `keepCase = true` for "Show on map", which does not need it. Drop `keepCase` there unless the lowercasing of "map" was the reason.
  - `ZeD_Prompt.lua:626/1093` measures caps; see 1.7.
- **`drawTextureScaled`:** the "never drawTextureScaled" rule is broken in ZeD_Belt.lua:691, 696, 697 and 724, ZeD_MainMenu.lua:351, ZeD_PixelParts.lua:101 and ZeD_TabPx.lua:108/113. All draw exact integer multiples of pixel art, so nothing stretches today. Switch them to `drawTextureScaledAspect` (identical output at exact aspect), or record the pixel-art exception in the rule.

### 5.3 Per-frame prints

- **No unconditional debug prints.** Two gated ones are fine as they are: ContextMenuRegistry's "uncategorized" and "no icon" logs are flag-gated and de-duplicated, and `MM.debugFire` is gated.
- **Error handlers that repeat every frame**, with no de-duplication:
  - FurnitureTab.lua:894 (every tick) and 858
  - InventoryRenderer.lua:238, 247 and 253 (per column, per frame)
  - ZeD_CharacterWindow.lua:4939 and ZeD_WorldWindow.lua:3858 (`ContainerControls focus:`)
  - ObjectCards.lua:193 and 899
  - Overrides/Wheels.lua:124
  - ZeD_Wheel.lua:222 (per cell) and 293
  - Overrides/Fishing.lua:160 and Overrides/Sleeping.lua:122
- **Suggested change:** one shared helper in Tokens.lua, `function ZeD.logOnce(key, msg) ZeD._logSeen = ZeD._logSeen or {}; local k = key .. "|" .. tostring(msg); if ZeD._logSeen[k] then return end; ZeD._logSeen[k] = true; print("[ZeD] " .. key .. ": " .. tostring(msg)) end`. Use it at each site (ContainerControls.lua:576 already does this by hand with `lastErr`).

### 5.4 The search placeholder says "flyers"

- **Where:** `ZeD_CharacterWindow.lua:3569`, `"Search flyers..."`.
- **Why:** the field searches the Notebooks and Papers shelves, so the label is wrong.
- **Suggested change:** `"Search..."`, or set the placeholder per shelf.

### 5.5 Chatty focus logging (low)

- **Where:** FocusManager prints on every D-pad move (`Input/FocusManager.lua:951`) and on every register, claim, transfer and release (253-326) and Y tap (1008-1066).
- **Why:** not per frame, but it fills console.txt during pad play. The QA scripts in Lua/ don't read these lines.
- **Suggested change:** gate them behind `_debugOverlay` or a `Focus.LOG` flag.

### 5.6 Hard-coded player 0 (low, split screen)

- **Where:** `getSpecificPlayer(0)` or `getPlayer()` in UI code, about 30 sites: AnimalsTab ×10, Settings ×5, MechanicsTab ×4, ZeD_CharacterWindow ×3, plus single uses elsewhere.
- **Effect:** a second split-screen player would see player one's data.
- **Suggested change:** use the window's or panel's `playerNum` where one is in reach.

---

## 6. Kahlua pitfalls

### 6.1 `ipairs` over a table with a nil hole (medium)

- **Where:** `ZeD_Belt.lua:1006`, `for _, win in ipairs({ cw, ww }) do`.
- **Why:** `cw` is nil whenever the Character window is closed, so the loop never reaches the World window. See top finding 8.
- **Suggested change:** `for _, win in ipairs({ cw or false, ww or false }) do`. The body already tests `win and ...`.

### 6.2 Width on `%s` (low, F9 debug overlay only)

- **Where:** `Input/FocusManager.lua:745` and `750`, `string.format("  %-5s %s -> %s", ...)`.
- **Why:** `%-5s` is the width-on-`%s` pitfall. Inside the overlay's pcall the legend fails silently.
- **Suggested change:** `local d = dir:upper(); d = d .. string.rep(" ", 5 - #d)` and build the line with `..`.

### 6.3 Clean

- No `%q`.
- No `gsub` with a function or table replacement. Chained `gsub` results are always parenthesised or truncated by argument position.
- No `ipairs`/`pairs` over Java lists. All Java lists use `:size()`/`:get(i)`, and the five 1-based loops correctly read `:get(i - 1)`.
- No Java enum compared to a string. The string compares (`getCategory`, `getFoodType`, `getContainerContentType`, `getType`) match vanilla's own usage, and enum values go through `tostring`.
- No `//`, `goto`, bit operators or utf8 library.
