# HOOK_MAP — every vanilla script that puts UI on screen, and what ZeD does about it

**Status:** living document, started S123 (Oct 12 2026) on stable 42.20.2.
**Rule:** if a vanilla script performs an action whose outcome is shown through vanilla UI, ZeD must either own the entry point (hook) and draw it from scratch, or leave it vanilla *on purpose*. Nothing is skinned. Each row names the exact vanilla entry point so the hook is a one-line decision, not an archaeology dig.

Legend — **Owned**: ZeD replaces it today · **Pass-through**: vanilla by decision · **Gap**: vanilla by omission, needs design then build.

## Owned today

| Surface | Vanilla entry point | ZeD hook |
|---|---|---|
| Inventory / loot pages | `ISInventoryPage.onKeyPressed` ("Toggle Inventory"), `ISInventoryPage.createMenu` | `ZeD_CharacterWindow.lua` removes the vanilla key handler, `_hideVanilla()` parks the pages; `Overrides/ContextMenu.lua` wraps `createMenu` |
| Context menus (inventory + world) | `ISInventoryPaneContextMenu.createMenu`, `ISWorldObjectContextMenu.createMenu`, `ISContextMenu:prerender` | `Overrides/ContextMenu.lua` spawns `ZeD_ContextMenu` and parks the vanilla menu off-screen |
| Tooltips | `ISToolTipInv` | `Overrides/Tooltip.lua` |
| Radio window | `ISRadioWindow.onEquip` on `OnEquipPrimary/Secondary` | `Overrides/RadioWindow.lua` removes the auto-open; `RadioTab.lua` is the surface (Q124) |
| Character info (health, skills, protection, thermal, identity) | `ISCharacterInfoWindow`, `ISHealthPanel`, `ISClothingInsPanel`, `ISFitnessUI` | Character window tabs; `ISHealthPanel:doBodyPartContextMenu` reused for treatment |
| Crafting (hand craft), building | `ISCraftingUI`, `ISEntityUI.HandcraftStart` | `CraftingTab.lua` / `BuildingTab.lua` on `CraftingCore` |
| World map (drawer + pop-out) | `ISWorldMap.ShowWorldMap` (M key) — *key not yet captured* | `MapsTab.lua` embeds `UIWorldMap`; S123 pop-out via `ZeD.MapsTab.openPopout` |
| Foraging | `ISSearchManager`, `ISSearchWindow`, `ISZoneDisplay` | `ForagingTab.lua` |
| Animals | `ISAnimalContextMenu`, `ISOpenAnimalInfo` | `AnimalsTab.lua` |

## Gaps — ordered by how often a long session hits them

| # | Surface | Vanilla entry point (file : function) | Trigger in play | Design target |
|---|---|---|---|---|
| 1 | **B42 entity windows** (crafting stations, furnaces, generators, build logic) | `Entity/ISEntityUI.lua : ISEntityUI.OpenWindow(_player, _entity)` → `ISEntityUI.GetWindowClass(_entity)` → `ISEntityWindow` / `ISEntityTabWindow` with component panels (`ISCraftBenchPanel`, `ISCraftLogicPanel`, `ISFluidSlotPanel`, `ISItemSlotPanel`, `ISEnergySlotPanel`) | Right-click any station → "Craft/Use"; every B42 bench | World window **Craft tab in station mode**: same recipe list, inputs come from the entity's slots; one organism, config-driven per component panel class (`ISEntityUI.GetComponentPanelClass`). Hook `OpenWindow` to route into the World window instead of spawning vanilla |
| 2 | **Vehicle dashboard** | `ISUI/PlayerData/ISPlayerDataObject.lua:124 : self.vehicleDashboard = ISVehicleDashboard:new(playerNum, chr)`; shown by the Java vehicle state when seated | Enter any vehicle | HUD organism, bottom-centre strip: speed, fuel, battery, engine, heater, lights, trunk, radio; gamepad = D-pad across controls, A toggles. Hook: replace `playerData.vehicleDashboard` at `ISPlayerDataObject` create time with a ZeD class exposing the same method names Java calls (`setVisible`, `update`) |
| 3 | **Vehicle mechanics** | `ISPlayerDataObject.lua:119 : self.mechanicsUI = ISVehicleMechanics:new(0,0,playerObj,nil)`; opened by `Vehicles/TimedActions/ISOpenMechanicsUIAction` | Right-click vehicle → Mechanics | World window **Vehicle tab** (contextual like Radio): parts list by area, condition bars, install/remove/repair verbs as header verbs on an ItemCard-style part card. Hook: `ISOpenMechanicsUIAction:perform` |
| 4 | **Vehicle radial / seat / AC / lightbar** | `ISVehicleMenu` (radial, `UIVehicleMenu`), `ISVehicleSeatUI`, `ISVehicleACUI`, `ISLightbarUI` | V key / vehicle context | Dashboard strip absorbs AC + lights + seats; radial stays pass-through until the dashboard ships |
| 5 | **Hotbar** | `ISPlayerDataObject.lua:113 : self.playerHotbar = ISHotbar:new(playerObj)` | Always (attached items) | Bottom-left strip with ZeD atoms; gamepad D-pad quick-select already routed through `ActionMap` `strip_hotbar` actions. Hook: replace `playerData.playerHotbar` |
| 6 | **Screen icons** — equipped-item HUD + health/moodle buttons | `ISUI/ISEquippedItem.lua:1270 : ISEquippedItem:new(x+10, y+10, 100, 250, playerObj)` (created in `ISEquippedItem.OnCreatePlayer` or `ISPlayerDataObject`) | Always (left edge) | Left-edge icon column in ZeD language: primary/secondary/back/belt icons + the character/health shortcut. Hook: the creation site above |
| 7 | **Moodles + clock + speed controls** | Java (`MoodlesUI`, `UIManager.getClock()`, `UIManager.getSpeedControls()`) — Lua only reads them | Always | **CaZio watch**: a ZeD HUD organism for time/date/weather/speed that replaces the Java clock *visually* (hide the Java panel, keep its API for state). Moodles: Java-drawn; a ZeD moodle strip can read `getPlayer():getMoodles()` and the Java panel can be hidden via `UIManager.getMoodlesUI(playerNum):setVisible(false)` (to verify) |
| 8 | **Fluid transfer** | `Fluids/ISFluidTransferUI.lua:15 : ISFluidTransferUI.OpenPanel(_player, _container, _source)` | Pour/fill context options | ZeD organism: two containers, amount slider, confirm; gamepad D-pad = amount, A = pour. Hook `OpenPanel` |
| 9 | **Fluid info bar / panel** | `Fluids/ISFluidInfoUI.lua`, `ISFluidBar.lua`, `ISFluidContainerPanel.lua` | Tooltip-level | Fold into ItemCard facts (fluid row) — small |
| 10 | **Fishing tension** | `Fishing/FishingManager.lua:37 : Fishing.ISTensionUI:new(player)` + `:addToUIManager()` | Casting | HUD meter in ZeD atoms; gamepad unchanged (engine-driven) |
| 11 | **Farming info** | `Farming/TimedActions/ISPlantInfoAction` → `ISFarmingWindow` | Right-click plant → Info | ItemCard-style plant card in the World drawer |
| 12 | **Camping / BBQ / generator info** | `TimedActions/ISCampingInfoAction`, `ISBBQInfoAction`, `ISGeneratorInfoAction` → `ISCampingInfoWindow`, `ISBBQInfoWindow`, `ISGeneratorInfoWindow` | Right-click object → Info | Same card pattern as 11 (fuel, state, verbs) |
| 13 | **Printed media reader** | `ISUI/ISLiteratureUI.lua:582 : ISLiteratureUI:new(...)`, `ISPrintMediaTextPanel`, `RecordedMedia/ISMediaInfo.lua:10` | Read magazine/newspaper, media info | Reader organism in the Character drawer (paper/ink System 7 page) |
| 14 | **Oven UI** | `TimedActions/ISOvenUITimedAction` | Use oven timer | Fold into the cooking Band + a timer row on the station card (see 1) |
| 15 | **Moveables info, extended placement** | `ISMoveableInfoWindow`, `ISExtendedPlacementUI` | Pick up / place furniture | Card + placement cursor in World window |
| 16 | **Sleeping** | `ISPlayerDataObject.lua:146 : self.sleepingUI = ISSleepingUI:new(playerNum)` | Sleep | Full-screen fade with ZeD type; low priority |
| 17 | **Medical check (other player)** | `TimedActions/ISMedicalCheckAction` | MP only | Pass-through |
| 18 | **Survival guide, safehouse, trading, pause/mod lists** | `SurvivalGuide/SurvivalGuide.lua`, `ISSafehouseUI`, `ISTradingUI`, `ISPauseModListUI` | Rare / MP / menu | Pass-through for now |
| 19 | **Post-death screen** | `ISUI/ISPostDeathUI.lua` | Death | Pass-through (menu-level) |

## Design notes carried from the director (Oct 12 2026)

- Dashboard, vehicle mechanics, CaZio watch and screen icons are the next planned surfaces. Suggested order given a long-session play test: screen icons (6) and CaZio watch (7) are always on screen and cheap; dashboard (2) + mechanics (3) are one design conversation (vehicle language); entity windows (1) are the largest but the most frequently hit.
- Each of these starts as a mockup in `ZeDUI/mockups/` before code (the ItemCard rule).

## How to add a hook

1. Find the row's entry point above and confirm it still exists on the current build (`grep -rn "<function>" media/lua/client`).
2. Decide owner: ZeD organism in a window tab, a HUD organism, or pass-through.
3. Hook at the entry point with the Overrides pattern (`Overrides/*.lua`: save the original, replace, call the original only when ZeD declines).
4. Add the surface to the QA bridge suites (`ZeDUI/tools/qa/`) so it is walked every session.
