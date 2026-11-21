# Beast day: what batches 1 and 2 left (Nov 21 2026, QA): batch 6 for Build

While writing the in-game proof of the 48 fixes (ZeDUI/tools/qa/vx_*.lua), one agent per area read each fix and a
second, skeptical one checked every claim below in the code. These are paths the fixes do not reach, side effects of
the fixes, and the parts Build itself marked "partly". All are read in the code; the vx scripts run in game next and
some of their checks will show these. Line numbers are at f22910bc2 unless said.

## A. Fix first: the player's saves, settings and other mods' files

### B6-1 Load Game: with Delete open, the target can change under it (W51's sibling)

ZeD_MainMenuSaves.lua:672 blocks row clicks only while Rename is open. With Delete open, a row click (:671-683), a group
fold (:616), typing in Find (:205) or the pad (joyDir :805-806 blocks up and down only for Rename) moves self.sel, and
delete() (:341-343) deletes self:selected(). The band re-prints the new title (:537), but a fold or a Find can switch an
irreversible Delete to a save the player never picked. Lock the target for Delete as Rename now does.

### B6-2 Reset settings can still empty another mod's files (W52's leftovers)

- ZeD_ModReset.lua:203-211 (addPrefix, called at :266): a name the mod's code builds from a quoted start, such as
  getFileWriter("Brita_" .. part), takes every Zomboid/Lua file starting with it, another mod's included. The whole-word
  and longer-id rules (holdsId :230-242, longerIds :246-260) guard only the id loop at :269-276. With Brita_Armor in
  use, Reset on Brita lists Brita_Armor.ini.
- :269-276: a longer-id mod whose file spells its id with a separator the id lacks is still taken: with BanditsWeekOne
  in use, Reset on Bandits lists Bandits_WeekOne.ini.
- A file left by an uninstalled longer-id mod is taken too: longerIds knows only installed or enabled mods.

### B6-3 Profiles: Delete or Replace profile, the pad can move the target (W38's sibling)

ZeD_MainMenuMods.lua: with the Delete or Replace profile question open (not a field mode, so joyDir :2361-2364 does not
stop it), pad up or down onto a profile row sets self.psel (:2403); deletePreset (:957-959) and updateProfile (:913-914)
read psel. The band re-prints psel (:1199, :1205). Mouse clicks are blocked since the fix (:2345).

### B6-4 ZeD setup: Lite then Full leaves every addition pending Off (W35's leftover)

Settings.lua:1001-1003 (working copy): lookStyle.onChange does nothing when Full is picked, so after Lite and then Full
the addition controls stay on the Vanilla set as a pending change, and an Apply pressed for anything else on the page
saves every addition Off. The finding named "clicks Full again" as a way back out: Full could put the addition controls
back to their stored values.

## B. Side effects of the fixes

### B6-5 Strip: with a controller assigned, a moving mouse or finger no longer moves the selection (W14)

ZeD_ContextMenu.lua:790 (809 in the working copy): `if not moved or self._joyfocus then zone = nil end`. open()
(:131-132) sets _joyfocus whenever JoypadState.players[pn+1] exists, which Overrides/ContextMenu.lua:43-44 notes is
true even when the right-click came from the mouse. So on a Steam Deck, or with a pad left plugged in, the strip's
selection and balloon no longer follow a moving pointer (clicks still run the clicked cell). Vanilla's
ISContextMenu:onMouseMove keeps hover with a pad; the `moved` test alone covers W14, since a hidden pad pointer does
not move.

### B6-6 A scale change while paused by the speed control shuts both windows until the game runs again (W36, partly)

Scale.lua:1147 (rootChanged) now runs at once (from Settings.lua:192 and the resolution hook at Scale.lua:289-292), so
reopenWindowsIfOpen (:1129) shuts the windows at once, but the reopen countdown (:1174) still runs only on OnTick.
Paused with the game's own speed control (not the pause menu), the windows are on screen; a UI scale pick on the
Select wheel (ZeD_DpadWheels.lua:561; the game lets Select through while paused) or a window resize on Auto shuts both,
and they stay gone until the game runs. The pause menu case is fine (the windows are hidden there).

### B6-7 Hint strip: holding a radio in front of a crafting station shows no hint at all (W55)

ZeD_HintStrip.lua:152-153 drops "Right-click More" whenever a radio is in either hand. The game checks a held device
(ISButtonPrompt.lua:612-621) before the crafting stations in front of the player (624 on), and a right-click there does
open the station's menu.

### B6-8 Title bar pins keep old-language words after a language change (W10)

ZeD_Pins.lua:216-220: the kept entry is handed back without checking ZeD._trGen or the test language (ZeD.tr's own
cache, InventoryRenderer, GridLayout and ReadMarks all check it). Small; entries of unpinned pins are never dropped.

## C. Paths a fix does not reach

### B6-9 Seated in a car, other ways to the ground still go out through a shut window (W5)

Build's window test covers InventoryRenderer.handleDrop only (:3834-3849). Still ungated:
- ZeD_WorldWindow.lua:5637 doTransfer's destIsFloor branch (from tryStripDrop :5654 and tryFloorTransfer :5672): seated,
  the World window keeps its empty Floor button and column; a row from the glove box or a seat dropped there goes out.
- ContainerControls.lua:220-225 (CT.moveItems to the floor): the World list stays on the Floor while seated, so the
  Character window's Transfer all and the pad's X grab (CT.moveToOther) drop everything outside.
- ItemCard.lua:929-930 (the card's Drop) and EquipmentTab.lua:1225 (the Equip card's drop). Vanilla's menu marks Drop
  not available there (ISInventoryPaneContextMenu.lua:642-652, ContextMenu_DropFromVehicle).
One ZeD wrapper around dropItem / onDropItems with vanilla's window test would cover all four.

### B6-10 Pins after loading a save still jump to another item of the same kind (W7 / W45)

ZeD_Pins.lua:65 (`if e and e.ft and not foundIds[tostring(id)]`): foundIds starts empty on every load, so a pin whose
item is not carried at the first title bar read (left in a crate, the car or on the floor when the game was saved) moves
for good to another carried item of its kind. B42 saves item ids (InventoryItem.save / load), so the by-type fallback
is needed only for older pin records: drop it, or keep it only for records written before the fix.

### B6-11 Animals: the rename box stays up after leaving the tab (W30)

AnimalsTab.lua:4305-4318 (AT._watch) ends a zone drawing and the highlight when the tab is left, but never calls
AT._endZoneEdit. The box is a child of the window (:759) and only drawZoneInfoBand hides it (:1716-1719). Rename on a
zone, press Loot or any other World tab: the box stays over that tab with the keyboard focus. (The commit message says
the rename ends there.) Fix: call AT._endZoneEdit(win) in _watch's gone loop, and/or hide win._animalsRenameEntry in
ZeD_WorldWindow's per-frame block for tab-only children (:4463-4467, as _mapTextEntry is).

### B6-12 Animals: opening an animal from outside keeps the old zone lit (W29)

AnimalsTab.lua:4272-4280 (AT.showAnimal) writes state.zoneName and state.view itself before navigate(win, "animal"), so
navigate's unlight test at :265 never fires. Routes: the hen house card's Info (ObjectCardHutch.lua:142-151), the
game's animal Info (WorldRoutes.lua WR.animal), a trailer's Info (MechTrailer.lua showInfo). Fix: in showAnimal call
AT._unlightZone(win) when state.view == "zone" and the animal's zone is not state.zoneName.

### B6-13 Animals with the drawer half folded: a zone drawing, a lit zone and a rename box are left behind (W28-W30)

AnimalsTab.lua:4301-4303 (animalsTabGone reads only _activeTab, which a fold keeps: WindowHalves.lua:469-475) and no
roll-up hold for a zone drawing or an open rename (WindowHalves.lua:797-798). Mouse, unpinned drawer half: the drawer
folds 2 s after the pointer leaves, and drawing on the ground needs the pointer to leave. The tab then stops drawing,
so presses on the ground draw nothing while the world menu stays off and the zones stay painted. Fix: hold the half
while AT._zoneDrawWin == win or a rename is open, or end them on fold.

### B6-14 Crafting list: any-surface recipes never read ready beside a table (W23)

CraftingTab.lua:574-576 builds the list's HandcraftLogic with no surface; the game refuses every AnySurfaceCraft recipe
without one (createCachedRecipeInfo ANDs canPerform with isCharacterInRangeOfWorkbench). Beside a table with everything
carried, Drill Plank reads Missing, Craft is dimmed and the card says "Needs a workbench or station nearby."
(CraftingCore.lua:2769). Vanilla's ISHandCraftPanel:update calls logic:setIsoObject(ISEntityUI.FindCraftSurface(player,
2)) every update; the scan needs the same, with the surface in its signature.

### B6-15 Crafting: chosen ingredients are swapped for the game's picks when they cannot cover the batch (W23)

CraftingCore.lua:2559 with :2597-2598: when the chosen type cannot cover the whole batch (one Handle chosen for Make
Stake x3, branches carried) or the chosen item is out of reach, startPickedCraft returns false and runStart quietly
starts the automatic craft. Refuse when picks exist and cannot be met: queue nothing, or say why.

### B6-16 Crafting: the alternatives list still reads N/1 (W24)

CraftingCore.lua:3001 (slotAlt zone inputDef = ing) with :1352 and :1389 (CC.enumerateAlts: need = inputDef.amount or
1): the card's ingredient row (:1277-1287) has need but no amount, so the list (drawn have/need, Molecules.lua:3780)
reads 2/1 for a slot that takes 4; both the mouse (:3526) and the pad (:3948) hand it that row. Fix: amount = inp.amount
on the ingredient row in CC.gatherDetail, or read inputDef.amount or inputDef.need. Lesser: CC.quickCraftCheck (:335)
counts one of each and the Journal's Recipes list uses only it (JournalTab.lua:1436), so a 4-plank recipe reads ready
with 1.

### B6-17 Title bar pins freeze while the inventory side is hidden (W8's sibling)

ZeD_CharacterWindow.lua:6326-6332: pins are built only in the inventory side's prerender, so while the side is rolled
under its rod (2 s after the pointer leaves an unpinned side) or a drawer covers the window, the title bar's pins keep
their last numbers. The doubled load itself is fixed.

### B6-18 Belt: a press that armed no drag-out stays armed when the belt hides (W40)

The new guard (ZeD_Belt.lua:2057) clears a lost release only when a drag-out was armed (self._out). A press that arms
none (an empty slot, a slot whose item is in a hand, another mod's box) sets _press alone (:2341-2345), and it stays if
the belt hides before the release (Esc's pause menu, or V while paused). A later press that starts off the belt and is
released over the same box passes onMouseUp's sameBox test (:2396-2406) and activates the slot (which can unequip its
item). Clearing _press in the same guard closes it.

## D. Small, or already marked "partly" by Build

- W42 second half: MapsTab.lua:2462 openPopout still makes a new ZeD_Window, ZeD_WorldMap (Java UIWorldMap) and text
  entry on every unfold; closePopout (2568-2607) only hides and removes, so each unfold leaves a map for the session.
- W48: every one of the ~190 keyboard map rows still gets a new hit table each frame (ZeD_KeyboardMap.lua:470), and
  the legend is re-wrapped every frame (:378). Far less than before.
- W18: HealthTab.lua:1391 calls startHelp every frame while the pointer or pad focus rests on a greyed Start: the live
  exerciseBlockKey and, when no block key applies, a full inventory search, once a frame. Use exSt.blockKey /
  exSt.avail[sel] from exerciseState in the draw.
- W22 trade-off: a modded service car whose name does not start with a game car's name (87chevyCapricePolice) now gets
  the civilian dash and loses its lightbar and siren buttons (ZeD_Dashboard.lua:116). The audit's other hint keeps
  them: a whole-word service word when the car has a lightbar (both callers have the car: ZeD_Dashboard.lua:2277,
  ZeD_SeatPopout.lua:121).
- W25: the espresso recipe still checks and crafts from carried things only (Appliances.lua:156 and :220).
- W32: zones are still keyed by name (AnimalsAlertPoller.lua:331-338, AnimalsTab.lua:204-216), so names shared through
  the game's own zone window, an older save or another mod still show one card twice. On the pad path from a zone
  card's menu a refused Save still runs zoneReturn (:3732-3735, :3701-3710): the page steps back and drops the typed
  name, and no path says the name is taken.
- W28: AT._overZeD (AnimalsTab.lua:246-256) covers only the two windows; a press on the belt, a pop-out or a context
  list while the drawing waits for its first corner still starts a corner under it.
- W43, very narrow and older than the fix: a pause within about 50 ms of a caught note is still un-paused
  (ZeD_Messages.lua:459, 839-850).
