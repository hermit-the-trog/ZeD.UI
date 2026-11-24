# ZeD-GUI add-on API (1.0)

*Nov 23 2026. The plug-in points ZeD keeps stable for add-ons, with the Loadouts and outfits feature as the worked
example: it talks to ZeD only through these (`ZeD_EquipLoadout.lua`, `ZeD_JournalLists.lua`, `ZeD_ListsMenu.lua`,
`ZeD_Lists.lua`). The code of each point is in the file named, with the same fields in a comment block.*

An add-on is a separate mod that requires ZeD-GUI (`require=\ZeD_UI` in its `mod.info`). It never reaches into
ZeD's private code: its `local` functions, its windows' `_fields`. It uses the calls below and the game's own hooks.
When a point you need is missing, ask for one rather than patching ZeD (ZeD Multi-Slot's `ADDON_GUIDE.md` shows how
an add-on is put together).

## The version and the rules

```lua
if ZeD and ZeD.API and (ZeD.API.VERSION or 0) >= 1 then ... end   -- ZeD_AddonAPI.lua
```

Every registry keeps these rules:

- **Idle when nothing registers.** No empty section, page, slice, chip, menu row or controller stop.
- **Your errors stay yours.** Each callback runs in `pcall`; an error is logged once (it also counts toward Safe
  mode) and only your part is left out for that frame. ZeD's own drawing goes on.
- **Same id again replaces.** A reloaded file does not show twice. Lower `order` comes first (default 100).
- **When to register.** Any time; `Events.OnGameBoot` (every file loaded) is the usual place:

```lua
function EL.register()
    if not (ZeD.API and (ZeD.API.VERSION or 0) >= 1) then return end
    ZeD.EquipmentTab.addSection("loadouts", { ... })
end
Events.OnGameBoot.Add(EL.register)
```

## Helpers

| Call | What it gives |
|---|---|
| `ZeD.API.call(where, fn, ...)` | `fn(...)` in pcall; nil and one log line when it throws |
| `ZeD.API.state(win, key, init)` | your own table on a ZeD window, kept as `win[key]` (pick a key of your own: Loadouts uses `_el`, `_jl`) |
| `ZeD.API.player(win)`, `ZeD.API.playerNum(win)` | the window's player and local player number (split-screen safe) |
| `ZeD_CharacterWindow.drawerPanel(win)` | the tab drawer's panel (parent your own boxes, a search field, to it) |
| `ZeD_CharacterWindow.cardOpen(win)`, `.activeTab(win)`, `.getWindow(pn)` | an item card over the tab; the tab showing; player pn's window |
| `ZeD_CharacterWindow.openTab(pn, tabId)` | the Character window open on a tab |
| `ZeD.EquipmentTab.focus(win)` / `setFocus(win, id)` / `clearSelection(win)` / `followY(win, id, y)` | the Equip tab's pad focus, closing its card, the pad's scroll-follow for your stop |
| `ZeD.EquipDoll.slotForLoc(loc, bands)`, `ZeD.EquipDoll.beltSlotFor(win, slotType)` | a worn place's or a belt slot's doll slot id |

The UI kit you draw with (so an add-on looks like ZeD): `ZeD.Atoms`, `ZeD.Molecules`, `ZeD.Focus.mark`,
`ZeD.Input.Focus`, `ZeD.Help.set`, `ZeD.Popups`, `ZeD_ContextList` (and the right-click rows' fields below),
`ZeD_ScrollbarState`, `ZeD_SearchField`, `ZeD.Stations.drawSelect`, `ZeD.PadGlyphs`, `ZeD.PutBack.queuing`,
`ZeD.Safe.on`, `ZeD.T` (tokens), `ZeD.TM` (text measure), `ZeD.tr`, `ZeD.uiSound`.

## The plug-in points

### Equip tab: a section under the doll and the lists, and a takeover (`EquipmentTab.lua`)

`ZeD.EquipmentTab.addSection(id, def)`: `order`, `visible(win)`, `beginFrame(win)` (every frame the tab draws, first),
`h(win, w)`, `draw(panel, win, x, y, w, view)` -> height, `onClick(win, x, y)` -> true when taken,
`focusables(win, elements)` (append your stops), `land(win, elements)` (every build: set `elements._focusIdx`),
`scrollKey(win)` -> a string (the stops are built again when it changes), and `takeover(win)` -> nil or
`{ render(panel, win, x, y, w, h), focusables(win), scroll(win), scrollKey(win) }`. While a takeover holds the drawer
ZeD hides the item card, the slots' zones and the tab's scroll, and the pad's stops are the takeover's alone.

Loadouts: the fold is the section, the to-do its takeover (`takeover = function(win) return EL.todoOpen(win) and
TAKEOVER or nil end`).

### Doll: marks in empty slots (`EquipDoll.lua`)

`ZeD.EquipDoll.addOverlay(id, { slots(win, bands) -> { [slotId] = g }, draw(panel, x, y, size, g) })`. A small-slot
row with a mark shows even while it is empty. Loadouts: what the applied loadout is missing, faint in a dashed box.

### Journal: a page (`JournalTab.lua`)

`ZeD.JournalTab.addPage(id, def)`: `key` (the tab's words), `order`, `visible()`, `render(panel, win, x, y, w, h)`,
`onClick`, `onRightClick`, `focusables(win)`, `modal(win)` (its stops alone hold the pad), `scroll(win)`,
`scrollKey(win)`, `syncChildren(win, shown)` (every frame), `searchField(win)` and `placeSearch(win, x, y, w, h)`
(your own search box in the header's place), `listOpen(win)` / `shutList(win)` (your pop-up list). Pages come after
ZeD's four. Open one by id: `ZeD.JournalTab.openPage(winOrPn, "loadouts")`; a page that hides while open goes back to
the first.

### Controller wheel: a slice (`ZeD_DpadWheels.lua`)

`ZeD.DpadWheels.addSlice("character", id, { order, visible(p, pn), entry(p, pn) -> slice })`: the slice has ZeD's own
shape (`name`, `icon`, `detail`, `off`, `sub(p, pn)` -> the inner ring, at most `ZeD.DpadWheels.MAX_INNER`, or
`run(p, pn)`). It goes after ZeD's slices, before the belt. `ZeD.DpadWheels.openCharTab(p, pn, tabId)` opens a
Character tab with the pad in it (Loadouts' ring opens the Equip tab's to-do).

### Item card: a mark, a body section, a model value (`ItemCard.lua`)

```lua
ZeD.ItemCard.addMark("lists", { order = 10, icon = "loadout", label = "UI_ZeD_Lists_Lists",
    state = function(item, pn) return { on = true, text = "in 1 loadout", hint = "..." } end,   -- nil: no mark
    activate = function(card, rect, pad) ... end })
ZeD.ItemCard.addSection("lists", { order = 10, draw = function(card, item, x, y, w, compact) return h end })
ZeD.ItemCard.addGen("lists", function() return L.gen end)   -- the card's model is built again when it changes
```

ZeD draws the chip after Favorite, No craft and Dispose, gives it the pointer's press and the pad stop
`toggle_<id>`, and leaves it out in Lite. Sections draw after the facts, before "Used to make". A mark's state is
part of the card's model (kept a moment): anything it shows must move a gen when it changes.

### Options: rows among ZeD's, showIf, the Additions preset (`shared/ZeD/AddonOptions.lua`)

- `ZeD.Options.addGroup { owner, title, after, rows }`: a group of your own on ZeD setup (version 1).
- A row's `showIf = "<option id>"`: the row is not shown while that option of the same owner is off.
- `ZeD.Options.addRows { owner, into = "UI_ZeD_Options_ZedAdditions", afterRow = "hiddenFacts", rows }`: your rows
  inside a ZeD group.
- `ZeD.Options.joinPreset { owner, id, presets = { v1, v2, v3 }, wasOn = item }`: the option becomes an addition:
  the presets (Vanilla, Vanilla Plus, Vanilla Accessible) set it, a change makes the preset read Custom, Lite and
  Defaults put it to `presets[1]`; `wasOn` is where it starts for a player who had ZeD saved before it existed.
  Join at file load, when the option is made.
- `ZeD.Settings.savedValue(owner, id)`: a value ModOptions.ini had when the game started (to carry a value saved
  under another owner).

Loadouts (`ZeD_Lists.lua`):

```lua
ZeD.Options.addRows { owner = "ZeD_UI", into = "UI_ZeD_Options_ZedAdditions", afterRow = "hiddenFacts",
    rows = { { "loadouts", "onoff" }, { "restock", "radio", showIf = "loadouts" } } }
ZeD.Options.joinPreset { owner = "ZeD_UI", id = "loadouts", presets = { 1, 2, 2 }, wasOn = 2 }
ZeD.Options.joinPreset { owner = "ZeD_UI", id = "restock", presets = { nil, 2, 3 } }
```

(The two options are still made by ZeD's `Settings.lua` under ZeD's owner until Loadouts ships as its own mod; then
the add-on makes them under its own owner and carries the player's values with `savedValue("ZeD_UI", "loadouts")`.)

### Pixel icons (`Atoms.lua`)

`ZeD.PxIcon.addWarm({ ids })`: your icons are asked for with ZeD's own, so they never draw blank the first time.
`ZeD.PxIcon.addMark(id, "blue" | "red" | "gold")`: the color of an icon's plus, minus or arrow (an id ZeD colors keeps
its color). The pictures live in `media/textures/ZeD/wheel/<size>/zw_<id>.png` (and `_mk.png` for the mark).

### Right-click rows

A row added to the game's context menu shows in ZeD's menu as it is (`ContextMenuRegistry.lua`). Fields ZeD reads on
an option besides vanilla's: `zedPx` (a ZeD pixel icon id for its picture), `zedCategory` (its group: a rule between
groups in the list look), `zedCheck` (true / false: a checkbox in the icon's place, in both looks). A row of your own
`ZeD_ContextList` takes `def.check` (a function or a bool, read live), `def.heading` and `def.keepOpen` (the list
stays after the press, for ticking boxes); Loadouts' item-card pop-up uses all three.

### Older points

`ZeD_CharacterWindow.addTab`, `ZeD_WorldWindow.addTab`, `ZeD.Belt.addBox` / `addMeter` / `addHold`,
`ZeD.GridLayout.register` (version 2), `ZeD.ItemRules.register`, `ZeD.ContainerControls.addProvider`,
`ZeD.ContainerGates.add`, `ZeD.ContainerGroups.add`, `ZeD.SkillsTab.addExtras`, `ZeD.HealthTab.addExtras`,
`ZeD.MapsTab.addExtension`, `ZeD.ItemFactsPanel.register`, `ZeD.ObjectCards.register`. `docs/reference/HOOK_MAP.md`
lists them with the mods that use them.
