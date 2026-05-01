# ZeD-UI deep audit against official PZ modding docs

**The official Project Zomboid modding documentation is a Java-side Javadoc reference — it does not document the Lua IS\* UI framework at all.** This means the primary documentation source for UI modding is split between `projectzomboid.com/modding/` (Java classes like `UIElement`, `UIManager`, `TextManager`) and the PZwiki plus community sources (Lua wrappers like `ISPanel`, `ISCollapsableWindow`, `ISContextMenu`). For a total UI overhaul mod, roughly 60% of the information you need lives outside the official docs entirely. Below is the complete audit across all six requested tasks.

---

## Task 1 — Full documentation structure inventory

The official docs at `projectzomboid.com/modding/` contain **~140 Java packages** organized as a standard Javadoc site. The pages return 403 on direct fetch but are fully indexed by search engines. Here is the complete inventory organized by functional domain.

### UI system (`zombie.ui`)
Contains **38 classes** directly relevant to UI modding: `UIElement` (base class for all UI), `UIManager` (global UI manager), `UIFont` (font enum with 21 values), `TextManager` (font rendering and measurement), `ScrollBar`, `TextBox`, `UITextBox2`, `ObjectTooltip` + `ObjectTooltip.Layout` + `ObjectTooltip.LayoutItem`, `ModalDialog`, `NewWindow`, `NewHealthPanel`, `DialogButton`, `GenericButton`, `HUDButton`, `ActionProgressBar`, `Clock`, `SpeedControls`, `MoodlesUI`, `DefaultMoodles`, `RadialMenu`, `RadialProgressBar`, `RadarPanel`, `UI_BodyPart`, `UI3DModel`, `UIDebugConsole`, `UIDialoguePanel`, `UINineGrid`, `UIServerToolbox`, `UITransition`, `UIWorldMap`, `UIWorldMapV1`, `FPSGraph`, `LoadingQueueUI`, `TutorialManager`, `TextDrawObject`, `TextDrawHorizontal`, `FontsFile`, `FontsFileFont`, `UIEventHandler` (interface), `VehicleGauge`.

### Lua bridge (`zombie.Lua`)
`LuaManager`, `LuaManager.GlobalObject` (massive — exposes hundreds of static methods as global Lua functions), `LuaEventManager`, `LuaHookManager`. This is the Java-Lua bridge via Kahlua.

### Game states (`zombie.gameStates`)
`MainScreenState` (main menu), `IngameState`, `GameLoadingState`, `GameStateMachine`, `ChooseGameInfo`, `ChooseGameInfo.Mod`, `ConnectToServerState`, `ServerDisconnectState`, `TISLogoState`, `AnimationViewerState`, `AttachmentEditorState`, `DebugChunkState`, `WorldMapEditorState`.

### Core engine (`zombie.core` + subpackages)
~30 subpackages covering: `Color`/`Colors`, `Core` (global engine state), `Rand`, `Language`/`Languages`, `GameVersion`, `Texture`/`SmartTexture`/`TextureDraw`, `Input`, `AngelCodeFont`, rendering pipeline (`zombie.core.opengl`, `zombie.core.sprite`), physics (`zombie.core.physics.Bullet`), networking (`zombie.core.raknet`), Steam integration (`zombie.core.znet`), profiling, logging, math utilities.

### World system (`zombie.iso` + subpackages)
~15 subpackages: `IsoObject`, `IsoGridSquare`, `IsoCell`, `IsoChunk`, `IsoWorld`, `IsoCamera`, `IsoMovingObject`, `IsoGameCharacter`, `IsoPlayer`, `IsoZombie`, `IsoSprite`, building system, weather, fog, lighting, region system.

### Other major packages
Characters (`zombie.characters` — 10+ subpackages for body damage, skills, traits, professions, actions, moodles), inventory (`zombie.inventory` + `zombie.inventory.types` with 20+ item classes), scripting (`zombie.scripting.objects` — Item, Recipe, VehicleScript, etc.), vehicles (`zombie.vehicles` — BaseVehicle, VehiclePart, VehicleManager), networking (`zombie.network` — GameClient, GameServer, PacketTypes), radio, randomized world, world map, AI, debug, modding (`ActiveMods`), population manager.

### What is NOT in the official docs
The entire Lua UI framework (`ISUIElement`, `ISPanel`, `ISCollapsableWindow`, `ISTabPanel`, `ISScrollingListBox`, `ISContextMenu`, `ISToolTip`, `ISButton`, `ISTextEntryBox`, `ISRichTextPanel`, `ISComboBox`, `ISTickBox`, `ISWindow`, `ISPanelJoypad`), all vanilla Lua game logic files, the events system (`Events.*`), context menu population hooks, and mod loading mechanics. These live in the game's `media/lua/` directory and are documented only by PZwiki and community sources.

---

## Task 2 — UI-specific intelligence

### ISUIElement → Java UIElement mapping

ISUIElement wraps Java's `zombie.ui.UIElement` via a `javaObject` field. The Lua IS\* classes use pseudo-OOP via `ISBaseObject:derive("ClassName")` with metatable inheritance. The hierarchy is:

```
ISBaseObject
 └── ISUIElement (wraps zombie.ui.UIElement)
      ├── ISPanel
      │    ├── ISPanelJoypad
      │    ├── ISContextMenu
      │    ├── ISButton
      │    ├── ISScrollingListBox
      │    ├── ISScrollBar
      │    ├── ISTextEntryBox
      │    ├── ISRichTextPanel
      │    ├── ISComboBox
      │    ├── ISTickBox
      │    ├── ISTabPanel
      │    ├── ISToolTip
      │    └── ISWindow
      │         └── ISCollapsableWindow
      └── ISToolTipInv
```

### UIElement fields (Java-side, all public)

| Type | Field | Notes |
|------|-------|-------|
| `float` | `x`, `y`, `width`, `height` | Position/size relative to parent |
| `boolean` | `visible` | Visibility flag |
| `UIElement` | `Parent` | Parent element reference |
| `final ArrayList<UIElement>` | `Controls` | Child elements list |
| `boolean` | `capture` | Whether element captures mouse input |
| `boolean` | `anchorTop/Bottom/Left/Right` | Anchoring for resize behavior |
| `boolean` | `followGameWorld` | Follows game world coordinates |
| `int` | `playerContext` | Split-screen player index |
| `boolean` | `defaultDraw` | Default drawing enabled |
| `KahluaTable` | `table` | Reference to the Lua table |
| `boolean` | `alwaysBack` | Forces element behind others |
| `boolean` | `bScrollChildren` | Whether children scroll |
| `boolean` | `bScrollWithParent` | Scrolls with parent |
| `String` | `clickedValue` | Click value string |
| `boolean` | `IgnoreLossControl` | Ignore focus loss |

### Draw primitives — exact Lua-side signatures

**Critical finding: `drawRect` and `drawText` have DIFFERENT alpha parameter positions.** 🆕

```lua
-- Rectangles: alpha FIRST after dimensions
self:drawRect(x, y, w, h, a, r, g, b)
self:drawRectBorder(x, y, w, h, a, r, g, b)

-- Text: alpha LAST in color args
self:drawText(text, x, y, r, g, b, a, UIFont.Small)
self:drawTextCentre(text, x, y, r, g, b, a, UIFont.Small)
self:drawTextRight(text, x, y, r, g, b, a, UIFont.Small)
```

All color values are **0.0–1.0 float range**, not 0–255. Coordinates in all draw calls are **relative to the element's position**, not screen-absolute.

### Texture drawing methods (Java UIElement, called via Lua lowercase wrappers)

```lua
self:drawTexture(texture, x, y, alpha)
self:drawTextureScaled(texture, x, y, w, h, alpha)
self:drawTextureScaledAspect(texture, x, y, w, h, r, g, b, a)
self:drawTextureScaledAspect2(texture, x, y, w, h, r, g, b, a)
self:drawTextureScaledCol(texture, x, y, w, h, r, g, b, a)
self:drawTextureScaledColor(texture, x, y, w, h, r, g, b, a)  -- boxed Double variant
self:drawTextureScaledUniform(texture, x, y, scale, r, g, b, a)
self:drawTextureAngle(texture, centerX, centerY, angle)
self:drawTextureAngle(texture, centerX, centerY, angle, r, g, b, a)
self:drawTextureTiled(texture, x, y, w, h, r, g, b, a)
self:drawTextureTiledX(texture, x, y, w, h, r, g, b, a)
self:drawTextureTiledY(texture, x, y, w, h, r, g, b, a)
self:drawTexture_FlippedX(texture, x, y, w, h, color)
self:drawSubTextureRGBA(texture, srcX, srcY, srcW, srcH, dstX, dstY, dstW, dstH, r, g, b, a)
self:drawUVSliceTexture(texture, x, y, w, h, color, u1, v1, u2, v2)
```

### Rendering pipeline

**The Lua UI rendering lifecycle is strictly two-phase — there is NO `postrender()`.** ⚠️

1. **`prerender()`** — Called before `render()`. ISPanel.prerender() draws `backgroundColor` rect and `borderColor` border. Always call `ISPanel.prerender(self)` first in overrides.
2. **`render()`** — Called after prerender(). Used for foreground content (text, textures, dynamic elements).

The `update()` method runs each tick for logic, separate from rendering.

### Mouse event methods

```lua
onMouseDown(x, y)          -- returns Boolean; true = consumed
onMouseUp(x, y)            -- returns Boolean
onMouseMove(dx, dy)        -- returns Boolean
onMouseMoveOutside(dx, dy) -- void
onMouseUpOutside(x, y)     -- void
onMouseWheel(del)          -- returns Boolean; del is scroll delta
onRightMouseDown(x, y)     -- returns Boolean
onRightMouseUp(x, y)       -- returns Boolean
```

**onRightMouseDown vs onRightMouseUp**: Context menus trigger on `onRightMouseUp`, not mouse-down. The call chain is `onRightMouseUp → ISObjectClickHandler.onObjectRightMouseButtonUp → ISContextManager.createWorldMenu`. This is why holding right-click to aim weapons doesn't open a context menu.

### Keyboard event methods

```lua
onKeyPress(key)     -- returns boolean
onKeyRelease(key)   -- returns boolean
onKeyRepeat(key)    -- returns boolean
setWantKeyEvents(bool) -- must be called to enable keyboard callbacks
isKeyConsumed(key)  -- check if key already consumed
```

### Position/Size methods

```lua
getX(), getY(), getWidth(), getHeight()
setX(v), setY(v), setWidth(v), setHeight(v)    -- setWidth/setHeight trigger onResize cascade
setWidthOnly(v), setHeightOnly(v)               -- set without triggering resize callbacks
setWidthSilent(v), setHeightSilent(v)           -- silent, no events at all
getAbsoluteX(), getAbsoluteY()                  -- screen-space coordinates
```

**There is no `setPosition(x, y)` convenience method** in the documented API — you must call `setX()` and `setY()` separately. ⚠️

**There is no `resizeWidget()` method** in the documented Java UIElement class or Lua ISUIElement. 🆕 If your knowledge base references `resizeWidget`, this is likely a Lua-side method added by ISCollapsableWindow or a specific subclass, not a base UIElement method.

### Font rendering and text measurement

```java
// TextManager (singleton via getTextManager() in Lua)
int MeasureStringX(UIFont font, String text)    // returns pixel width
int MeasureStringY(UIFont font, String text)    // returns pixel height
int getFontHeight(UIFont font)                   // returns font line height in pixels
AngelCodeFont getFontFromEnum(UIFont font)
```

Lua usage:
```lua
local tw = getTextManager():MeasureStringX(UIFont.Small, "Hello")
local th = getTextManager():getFontHeight(UIFont.Small)
```

Return types are `int` — pixel values truncated from the underlying bitmap font metrics. PZ uses **AngelCodeFont** (bitmap fonts), so actual pixel sizes come from font asset files. No runtime scale multiplier API is exposed to Lua; scaling is achieved by choosing different `UIFont` enum values. The `AutoNormSmall/Medium/Large` variants auto-normalize to display DPI.

### UIFont enum values (21 constants)

`Small`, `Medium`, `MediumNew`, `Large`, `Massive`, `MainMenu1`, `MainMenu2`, `Cred1`, `Cred2`, `NewSmall`, `NewMedium`, `NewLarge`, `Code`, `Title`, `Dialogue`, `Intro`, `Handwritten`, `DebugConsole`, `AutoNormSmall`, `AutoNormMedium`, `AutoNormLarge`.

### addToUIManager vs addChild

**`addToUIManager()`** registers a top-level element with the Java-side UIManager. Internally calls `instantiate()` if not already done. Adds the element to `UIManager.UI` — the root ArrayList of all top-level elements.

**`addChild(element)`** adds a child to the parent's `Controls` list. Children render relative to parent coordinates and are managed by the parent, not the UIManager directly.

### Widget visibility

`setVisible(false)` hides the element but keeps it in the manager/parent. `removeFromUIManager()` deregisters from the Java manager entirely. Standard show/hide pattern:

```lua
-- Show:
myUI:setVisible(true); myUI:addToUIManager()
-- Hide:
myUI:setVisible(false); myUI:removeFromUIManager()
```

### Z-order / layering

```java
void bringToTop()                  // moves self to front of z-order
void BringToTop(UIElement child)   // moves a child to front within parent
void backMost()                    // moves self to back
void setAlwaysOnTop(boolean b)     // always rendered on top
boolean alwaysBack                 // field: always rendered behind siblings
```

UIManager renders elements in list order — last in list = visually on top. `bringToTop()` moves the element to the end of the list. `alwaysBack` and `setAlwaysOnTop` override the natural list order.

### Parent-child coordinate system

`x, y` are relative to parent (or screen if no parent). `getAbsoluteX()` / `getAbsoluteY()` return screen-space coordinates by accumulating parent offsets. Draw calls within `render()` and `prerender()` use element-local coordinates (the engine translates to absolute coordinates internally). Scroll offsets are tracked separately via `getXScroll()` / `getYScroll()` — `getXScrolled()` returns position + scroll offset.

### Stencil/clipping system

```lua
setStencilRect(x, y, w, h)   -- clip children to rect
clearStencilRect()
suspendStencil()              -- temporarily disable clipping
resumeStencil()               -- re-enable clipping
repaintStencilRect(x, y, w, h)
setMaxDrawHeight(v)
clearMaxDrawHeight()
setRenderClippedChildren(bool)
```

### ISPanel defaults

```lua
backgroundColor = {r=0, g=0, b=0, a=0.5}    -- semi-transparent black
borderColor = {r=0.4, g=0.4, b=0.4, a=1}     -- gray border
```

ISPanel.prerender() draws the background rect using `backgroundColor` then the border using `borderColor`. Overriding `backgroundColor` in `new()` before the first prerender call controls what gets drawn.

### ISCollapsableWindow

Derives from ISWindow (which derives from ISPanel). Provides title bar, close button (X), collapse/pin button, and draggable behavior. `createChildren()` auto-creates the close button, pin button, and resize widget. Key methods: `setTitle(title)`, `close()`. Title bar height is typically **16–24px** depending on font scale.

### ISScrollingListBox

```lua
ISScrollingListBox:new(x, y, w, h)
-- Key fields/methods:
.itemheight = 15                             -- height per row in pixels
.font = UIFont.Small                         -- item text font
.drawBorder = true                           -- draw border
.selected                                    -- 1-based index of selected item
:addItem(text, item)                         -- add item (stores {text=text, item=item})
:clear()                                     -- remove all items
:setOnMouseDownFunction(target, func)        -- set click callback
```

Automatically creates an ISScrollBar child when content exceeds view height.

### ISContextMenu construction

```lua
-- Creating options:
context:addOption(name, target, onSelect, param1, param2, ..., param10)
-- Callback: function(target, param1, param2, ...)
-- Leaving onSelect nil = unclickable header/divider

-- Accessing options:
context:getOptionFromName("My option")

-- Submenus:
local option = context:addOption("Parent")
local subMenu = context:getNew(context)
context:addSubMenu(option, subMenu)

-- Option properties:
option.notAvailable = true          -- greyed out
option.toolTip = tooltipObject      -- ISToolTip
option.iconTexture = getTexture()   -- left-side icon
```

### ISToolTip and ISToolTipInv

**ISToolTip** fields: `description` (supports ISRichTextPanel tags), `texture`, `footnote` (plain text only, no rich text), `name`. Created via `ISToolTip:new()` or pooled via `ISWorldObjectContextMenu.addToolTip()`.

**ISToolTipInv** handles inventory item tooltips specifically. Override only `ISToolTipInv:render()` — never copy the entire file.

### ISContextManager

Located at `media/lua/client/ISUI/ISContextManager.lua`. Its primary method is `createWorldMenu` (line ~28). It coordinates right-click context menu creation, receiving events from `ISObjectClickHandler` and delegating to `ISMenuContextWorld` / `ISWorldObjectContextMenu`. Not a general-purpose context manager — strictly the world object context menu orchestrator.

---

## Task 3 — Main menu and screen system

### MainScreen.lua architecture

Located at `media/lua/client/OptionScreens/MainScreen.lua`. Key functions: **`LoadMainScreenPanel()`** (~line 1996) is the top-level function called from Java's `MainScreenState` to initialize the main menu Lua UI. **`LoadMainScreenPanelInt()`** (~line 2087) is the internal implementation. **`MainScreen:instantiate()`** (~line 800) creates the main menu screen instance.

### Screen registration and transitions

The Java side uses a state machine pattern in `zombie.gameStates.GameStateMachine`:

- **`MainScreenState`** — Main menu
- **`GameLoadingState`** — Loading screen
- **`IngameState`** — In-game
- **`TISLogoState`** — TIS logo splash
- **`ConnectToServerState`** — MP connection

`UITransition` class handles fade transitions: `init(float duration, boolean fadeIn)`, `update()`. UIManager provides `FadeIn(seconds)` and `FadeOut(seconds)` static methods plus `FadeAlpha`, `FadingOut`, `FadeInTime`, `FadeInTimeMax` fields.

### Hook points for main menu replacement

`OnMainMenuEnter` event fires upon entering the main menu. Override/monkey-patch functions in `MainScreen.lua` (e.g., `MainScreen:instantiate()`, `LoadMainScreenPanel()`, `LoadMainScreenPanelInt()`). Community mods demonstrate this pattern: UI Reshaded overrides `MainScreen.lua`'s `instantiate`, `LoadMainScreenPanel`, `LoadMainScreenPanelInt`, and `MainOptions.lua`'s `create`. Related files loaded during startup include `CharacterCreationHeader.lua`, `CharacterCreationMain.lua`, `CharacterCreationProfession.lua`, `LastStandChallenge.lua`, `LoginScreen.lua`, `MainOptions.lua`.

In Build **42.16.0**, TIS "changed default size of the various main screen UIs," indicating active modification of MainScreen elements.

### Video playback and CRT effects

**`getVideo()` is NOT part of the public Lua modding API.** No video playback, cinematic control, or CRT/monitor shader effect hooks are exposed to Lua modders. The intro movie is handled internally by the Java engine. `OnPreUIDraw` and `OnPostUIDraw` events can be used for custom overlay rendering, but this does not provide shader-level control. CRT effects, if they exist, are Java-side rendering not exposed through the documented API.

---

## Task 4 — Contextual tabs and game state

### ISTabPanel

Located at `media/lua/client/ISUI/ISTabPanel.lua`. Derives from ISPanel.

```lua
:addView(name, view)        -- register tab with name and ISPanel view
:removeView(view)           -- remove tab by view reference
:activateView(name)         -- switch to tab by name
:getActiveView()            -- returns currently active view panel
:getActiveViewName()        -- returns name string of active tab
:onActivateView(viewName)   -- callback invoked on tab switch (override this)
```

Tab names serve as both display labels and lookup keys. Only the active view is rendered. Tab panels dynamically adjust height based on active tab content.

### Events system — full UI-relevant catalog

**Lifecycle/boot events:**
`OnGameBoot` (after startup, before server/ files load), `OnPreGameStart` (save loading), `OnGameStart` (session active), `OnMainMenuEnter` (entering main menu), `OnCreateUI` (UI initialized — ideal for custom UI creation), `OnCreatePlayer(playerIndex, player)`, `OnResetLua` (after Lua reload), `OnGameStateEnter` (documented as TOS-only; broken for other states).

**Per-frame/tick events:**
`OnTick(numberOfTicks)`, `OnPlayerUpdate(player)`, `OnRenderTick`, `OnPreUIDraw`, `OnPostUIDraw`.

**Input events:**
`OnKeyPressed(key)`, `OnKeyStartPressed(key)`, `OnCustomUIKey(key)`, `OnCustomUIKeyPressed(key)`, `OnCustomUIKeyReleased(key)`, `OnMouseDown(x,y)`, `OnMouseUp(x,y)`, `OnMouseMove(x,y,dx,dy)`, `OnRightMouseDown(x,y)`, `OnRightMouseUp(x,y)`, `OnObjectRightMouseButtonDown`.

**Context menu events:**
`OnFillInventoryObjectContextMenu(playerNum, context, items)`, `OnFillWorldObjectContextMenu(playerNum, context, worldObjects, test)`, `OnPreFillInventoryObjectContextMenu`, `OnPreFillWorldObjectContextMenu`, `OnClickedAnimalForContext`, `onFillSearchIconContextMenu`.

**Display events:**
`OnResolutionChange(oldW, oldH, newW, newH)`.

**Container/inventory events:**
`OnRefreshInventoryWindowContainers`.

**Other notable:**
`DoSpecialTooltip` (fires when updating tooltip of IsoObject with special tooltip), `AddXP` (after local character gains perk XP), `OnPreMapLoad`, `OnLoadedTileDefinitions`, `OnLoadSoundBanks`.

The authoritative event documentation is **PZEventDoc** (`github.com/demiurgeQuantified/PZEventDoc`) which generates the PZwiki events list. **PZEventStubs** provides EmmyLua-annotated stubs for IDE intellisense.

### Context menu population hooks

```lua
-- World object right-click:
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    if test then return end  -- test=true means just checking for interactive objects
    context:addOption("My Action", playerNum, myCallback)
end)

-- Inventory item right-click:
Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)
    context:addOption("My Item Action", items, myItemCallback)
end)
```

The `worldObjects` table: first object is whatever the mouse hit directly. The engine also adds nearby door, window, thumpable, hoppable, and tree objects. Common pattern: get the square from the first object and iterate through its objects.

### Contextual panel show/hide

No formal documentation exists for how contextual panels (fishing, foraging, animal care) are shown/hidden based on game state. These panels use ISTabPanel internally and are triggered by game logic — they check player actions/states in their `update()` methods and toggle visibility accordingly. No Events.\* hooks exist specifically for panel state changes.

---

## Task 5 — Cross-reference against known quirks (Q1–Q33)

### ⚠️ drawFrame=false kills vanilla title bar rendering
**Status: NOT DOCUMENTED.** No official or community documentation found. The `drawFrame` property controls border rendering in ISPanel. The specific interaction with ISCollapsableWindow's title bar is community-discovered but not publicly documented.

### ⚠️ resizeWidget requires bringToTop() to take effect visually
**Status: `resizeWidget` DOES NOT EXIST in documented API.** The Java UIElement class has no `resizeWidget` method. Layout resizing is done via `setWidth()` / `setHeight()` which trigger `onResize()` cascade. If your codebase uses `resizeWidget`, it is likely a Lua-side method defined in ISCollapsableWindow or a custom method, not a base UIElement method. The interaction with `bringToTop()` cannot be confirmed from docs.

### ⚠️ backgroundColor must be set BEFORE parent's prerender() call
**Status: PARTIALLY CONFIRMED.** ISPanel.prerender() draws the background rect using `backgroundColor`. Since prerender reads the field at draw time, setting it after the prerender call in the same frame would have no visible effect until the next frame. The docs confirm the render order: prerender (reads backgroundColor) → render. Setting backgroundColor in `new()` before any frame is drawn is the correct pattern.

### onMouseWheel positive value = scroll DOWN (inverted)
**Status: PARTIALLY CONFIRMED.** Community reports confirm scroll direction inconsistency across platforms (Mac vs PC). The `onMouseWheel(del)` parameter sign convention is platform-dependent. The official API documents only the method signature `Boolean onMouseWheel(double del)` without specifying the sign convention.

### ModOptions getValue() returns int not boolean for checkbox
**Status: NUANCED.** ModOptions is native to Build 42 (`PZAPI/ModOptions.lua`). The PZwiki documents tickbox options returning boolean via `option:getValue()`. However, Kahlua stores all numbers as doubles — there is no integer type. The confusion likely arises from the Kahlua bridge where Java int return values are received as Lua numbers. **Known bug (42.10.0):** `onclickfunc` has improperly passed arguments (arg4 arrives as arg3). 🆕

### Surface alphas: 0.92 dark/light, 0.95 high contrast
**Status: NOT DOCUMENTED.** No official documentation of specific alpha values for surface rendering modes.

### Scrollbar uniform width is 14px
**Status: NOT DOCUMENTED.** No explicit documentation of scrollbar pixel width.

### Edge flags prevent double-thick borders on title bar edges
**Status: NOT DOCUMENTED.** No official documentation of edge flag behavior.

### ⚠️ setX/setY does not trigger layout recalculation
**Status: CONFIRMED CONSISTENT.** The Java API provides `setX(double)` and `setY(double)` as simple position setters. The resize cascade is triggered by `setWidth()` / `setHeight()` (which call `onResize()`), not by `setX()` / `setY()`. The API also provides `setWidthOnly()` / `setHeightOnly()` and `setWidthSilent()` / `setHeightSilent()` specifically to bypass the resize cascade. This confirms that position changes via setX/setY do not trigger layout recalculation.

### addToUIManager puts widget at top of z-order stack
**Status: CONFIRMED CONSISTENT.** `addToUIManager()` adds the element to `UIManager.UI` (an ArrayList). New elements are appended to the end of the list. UIManager renders in list order — last rendered = visually on top. Therefore adding via `addToUIManager()` places the widget at the top of the z-order.

### Font rendering MeasureStringX/Y returns pixel values based on active font scale
**Status: CONFIRMED.** `TextManager.MeasureStringX(UIFont, String)` and `MeasureStringY(UIFont, String)` both return `int` — pixel values from the underlying AngelCodeFont bitmap metrics. No runtime font scale multiplier exists; scaling is determined by the UIFont enum value selected and the font asset files.

### ISTabPanel does not fire a tab-change callback by default — must be monkey-patched
**Status: PARTIALLY CONTRADICTED.** ISTabPanel does have an `onActivateView(viewName)` method that is called when tabs switch. However, this is an **instance method override**, not a global `Events.*` hook. You override it on the specific ISTabPanel instance or subclass — no monkey-patching required. There are no global `OnTabAdded`/`OnTabRemoved` events in vanilla (those exist only in the Events Plus API mod). ⚠️

### ISContextMenu items can be submenus, options, or dividers — no other types natively
**Status: CONFIRMED.** PZwiki documents three item types: regular options (via `addOption`), submenus (via `addSubMenu`), and divider-like headers (options with nil `onSelect` callback). Build 42.8.0 added `getItem(index)`, `addItem()`, and `addUniqueItem()` with tooltip arguments, but these are variants of the same three types.

### Tooltip positioning: ISToolTip follows mouse, ISToolTipInv anchors to item row
**Status: PARTIALLY CONFIRMED.** ISToolTip and ISToolTipInv are separate implementations. The behavioral difference (mouse-following vs item-anchored) is implied by their separate codebases and confirmed by community modding patterns, but not explicitly documented as a specification.

### New quirk candidates for Q34+

🆕 **Q34 — drawRect vs drawText alpha parameter order mismatch.** `drawRect(x, y, w, h, a, r, g, b)` has alpha FIRST after dimensions, but `drawText(text, x, y, r, g, b, a, font)` has alpha LAST in the color arguments. This is a critical inconsistency that can cause subtle rendering bugs.

🆕 **Q35 — Both `onresize()` and `onResize()` exist as separate methods on Java UIElement.** Both lowercase and camelCase variants exist in the Java class. In Lua, modders typically override `onResize()`, but the dual existence may cause confusion if the wrong one is called.

🆕 **Q36 — `postrender()` does not exist.** The rendering lifecycle is strictly `prerender() → render()`. There is no third phase. Any references to postrender in the knowledge base are incorrect.

🆕 **Q37 — KahluaTable stores all numbers as double.** No integer type exists in the Lua-Java bridge. This affects checkbox state retrieval, array indexing, and any value expected to be an integer. Boolean values may arrive as `0.0`/`1.0` rather than `false`/`true`.

🆕 **Q38 — ClassCastException: ArrayList vs KahluaTable.** Java ArrayLists returned from API calls cannot be used with Lua table functions like `table.insert`. They require Java-style iteration (`list:get(i)`, `list:size()`).

🆕 **Q39 — UI FBO rendering.** UIManager supports rendering UI into an offscreen FBO at a lower framerate than the game (`UIManager.useUIFBO`, `UIManager.UIFBO`). This can cause UI update lag — UI elements may not refresh every frame when FBO mode is active.

🆕 **Q40 — `server/` Lua files are NOT loaded at OnGameBoot.** For clients, files in `lua/server/` have not loaded when `OnGameBoot` fires. They load only when a save is started/loaded. Server files are unloaded when exiting a save.

🆕 **Q41 — ISPanelJoypad:ensureVisible() nesting bug.** Fixed in B42.8.0 — didn't work for elements inside another UI element, affecting nested panels in options screens.

🆕 **Q42 — ModOptions onclickfunc argument shifting bug.** Button callbacks have arguments improperly passed — arg4 arrives as arg3 (confirmed bug in 42.10.0+).

🆕 **Q43 — `setWidthSilent` / `setHeightSilent` exist as distinct methods from `setWidthOnly` / `setHeightOnly`.** Four separate methods exist for setting dimensions with different side-effect profiles: `setWidth` (full cascade), `setWidthOnly` (minimal), `setWidthSilent` (no events), and direct field access `self.width =` (Lua-only, no Java notification).

---

## Task 6 — Additional relevant intelligence

### Mod loading order and event timing

**Loading sequence:**
1. Java engine initializes
2. `shared/` Lua files load (vanilla first, then mods in load order)
3. `client/` Lua files load (vanilla first, then mods in load order)
4. **`OnGameBoot`** fires (⚠️ `server/` files NOT yet loaded)
5. Main menu appears → **`OnMainMenuEnter`**
6. Player loads a save → `server/` files load
7. **`OnPreGameStart`** → **`OnGameStart`** → **`OnCreateUI`** → **`OnCreatePlayer`**

Mods load in the order specified by the player's mod list. Later mods override earlier mods for files at the same relative path. For Lua hooks, later mods' callbacks fire after earlier mods'.

### Build 42 mod structure (breaking change from Build 41)

Build 42 requires a **mandatory `common/` directory** (even if empty) and supports **versioned folders** (`42/`, `42.1/`, etc.). The `mod.info` can exist at root level or in version-specific folders. Build 41's flat `media/` structure still works for B41 but is not recognized for B42 features.

```
mods/MyMod/
├── common/          ← MANDATORY for Build 42
│   └── media/       ← shared assets (models, textures)
├── 42/              ← version-specific code
│   ├── media/lua/client/...
│   ├── mod.info
│   └── poster.png
└── mod.info         ← root mod.info
```

### Build 42-specific UI changes affecting overhaul mods

**42.1.0:** Crafting panels responsive to font/screen size changes; recipe panel auto-expand. **42.6.0:** Sidebar icon resizing; scroll bars added to craftPanel inputs. **42.7.0:** Mouse-over highlighting in Building UI and Crafting UI. **42.8.0:** Fluid indicators in Crafting Menu; item icons in context menus; ISPanelJoypad:ensureVisible fix. **42.9.0:** Extended placement UI with rotation/movement. **42.12.0:** Controller navigation overhaul; crafting/carpentry UIs use newer controller-navigation method; background under radial-menu text. **42.13.0:** Crafting panel locked by default; "show all recipe" tickbox; plastering/wallpaper/painting moved from RMB context menu to Build Menu. **42.16.0:** New highlight on mouse-over in loot UI; changed default main screen UI sizes; Vehicle Lightbar Control Panel repositionable.

### Kahlua bridge details

PZ uses modified **Kahlua** (Java Lua 5.1 implementation). `LuaManager.GlobalObject` exposes hundreds of static methods as global Lua functions. `LuaManager.Exposer` exports classes as global Lua tables. Java class **fields are NOT accessible from Lua** — only methods. Java reflection does not work. Standard Lua modules `io.*` and `os.*` are not available. All numbers stored as `double` in KahluaTable. Java arrays/lists must be iterated with Java-style methods (`list:get(i)`, `list:size()`), not Lua table functions.

The `ISUIElement.javaObject` field holds the reference to the Java `zombie.ui.UIElement` instance. `instantiate()` creates this backing Java object. Drawing methods on ISUIElement delegate to the Java UIElement's draw methods (Lua lowercase → Java uppercase: `drawRect` → internally calls Java rendering pipeline).

### Mod compatibility patterns for UI replacement

**Never replace entire IS\*.lua files** — override individual functions instead. Store a reference to the original, then overwrite:

```lua
local original_render = ISToolTipInv.render
function ISToolTipInv:render()
    -- custom rendering
    original_render(self)
end
```

**File path conflicts** are the primary conflict source. Use unique subfolders (`media/lua/client/ZeDUI/`) to avoid clashes. Framework mods like NeatUI demonstrate layered approaches where a base framework provides hooks and child mods build on top. Load order is critical — use `loadModAfter=` in `mod.info` to declare dependencies.

Known conflict patterns: multiple mods overriding `ISInventoryPane.lua`, `ISInventoryPaneContextMenu.lua`, or `ISWorldObjectContextMenu.lua` will clash. Community reports confirm "Clean UI + Bigger Inventory = entire interface disappears" — demonstrating that UI overhaul mods are particularly susceptible to incompatibility.

### ImGui debug tool

Build 42 added ImGui as a debug tool (launch with `-imgui` parameter). Allows inspecting all game UI elements in hierarchy view, inspecting variables on plotted graphs, and viewing in-game textures. **Restricted to debug mode only** — it breaks multithreaded rendering on OpenGL. TIS has indicated plans for future "UI middleware" for gameplay UI overhaul, which could significantly change the modding surface area for UI mods.

---

## Coverage gap summary

The official docs cover Java-side classes thoroughly but have **zero coverage** of the Lua UI framework that modders actually use. The following critical areas have no official documentation at all and rely entirely on community knowledge:

- ISUIElement lifecycle and method signatures
- ISPanel/ISCollapsableWindow/ISWindow patterns
- ISTabPanel behavior and callbacks
- ISContextMenu construction patterns
- ISToolTip/ISToolTipInv positioning behavior
- Context menu population hooks and call chains
- Main menu architecture and override patterns
- Mod loading order and event timing
- All 33+ engine quirks in the ZeD-UI knowledge base
- Parent-child coordinate system conventions
- Background rendering order and backgroundColor behavior
- The distinction between addToUIManager and addChild

For a total UI overhaul mod, the official Javadoc is primarily useful as a reference for the underlying Java types, method signatures, and field names — but the actual modding patterns, lifecycle management, and behavioral quirks must come from source code inspection and community documentation.