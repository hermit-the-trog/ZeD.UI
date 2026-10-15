# PZAPI Knowledge Bank — ZeD-UI Project
## Battle-tested knowledge from 83 sessions of PZ Build 42 modding

---

## PZ ENGINE QUIRKS (confirmed through debugging)

### Mouse Events & Hit Testing

**Q1: Nested panel mouse events break at 4+ levels.**
ISPanel children nested deeply don't receive onMouseDown/onMouseMove/hover.
**Fix:** Hit testing via `update()` with raw screen coordinates:
```lua
local mx = getMouseX() - self:getAbsoluteX()
local my = getMouseY() - self:getAbsoluteY()
```

**Q2: isMouseButtonDown(0) is the only reliable mouse state check.** Global, works regardless of focus.

**Q3: setCapture(true) can miss onMouseUp.** Add safety release in update().

**Q4: Child panels eat parent mouse events.** Detect in both onMouseDown AND update().

**Q5: onMouseWheel positive delta = scroll DOWN (inverted).**

**Q5b: isMouseOver() doesn't account for sibling panel Z-order.** A panel reports mouse-over even when a sibling overlaps it at the same screen coordinates. **Fix:** Check panel-local bounds explicitly: `mx >= 0 and mx < w and my >= 0 and my < h`.

**Q5c: onMouseMove stops firing when mouse leaves panel quickly.** Hover states set in onMouseMove become stale if the cursor exits the panel in a single frame. **Fix:** Clear hover states in the draw/render cycle by checking mouse position against the component's own rect every frame.

### Panel Lifecycle

**Q6: initialise() must be called exactly once.** Calling twice severs child references.

**Q7: addChild() triggers instantiate().** Set anchors BEFORE addChild.

**Q8: self:getChildren() returns Lua table keyed by ID.** Use pairs(), not getChildAt().

**Q9: drawFrame = false suppresses vanilla title bar.**

**Q10: ISCollapsableWindow expects resizeWidget/pinButton/collapseButton to exist.**

### Drawing & Rendering

**Q11: Set backgroundColor BEFORE parent prerender call.** PZ draws bg first.

**Q12: No native triangle/polygon drawing.** Build from stacked 1px rects.

**Q13: setStencilRect/clearStencilRect for clipping.**

**Q14: getTimestampMs() available everywhere.** Reliable for animations.

**Q15: Texture path shadowing for overrides.** 1×1 black PNGs scale to fullscreen.

**Q15b: Bitmap fonts lack arrow/chevron glyphs.** PZ's custom bitmap fonts (Fira Mono, Fira Sans Condensed — all generated at fixed pixel sizes) do not reliably render `^`, `v`, `>`, `<`, `▶`, `▼` or other directional glyphs. Characters either render as blank/tofu or misalign. **Fix:** Use `ZeD.Atoms.drawTriangleUp/Down/Right/Left` (geometric rect-stacking in AtomExtensions.lua) for all directional indicators. Never use drawText with arrow characters.

### Scrollbar & Resize

**Q16: Scrollbar must be plain Lua table, NOT ISPanel child.** Avoids nested event bugs.

**Q17: reserveBottom = 0 on scrollbar when parent excludes grow box.**

### File Load Order

**Q21: Namespace tables must use `or {}` guard.** PZ re-executes files unpredictably.

### ModOptions API

**Q18: Colon syntax, getValue() returns integer INDEX not string.**

### Java Bridge

**Q19: ISToolTipInv uses item:DoTooltip(ObjectTooltip) — pure Java rendering.**
Cannot style content from Lua. Must read item properties via getters and render yourself.

**Q20: safeGet pattern for unreliable Java getters.**
Not all item types expose the same methods. Calling a nil method crashes.
```lua
local function safeGet(item, methodName, ...)
    local fn = item[methodName]
    if not fn then return nil end
    local ok, result = pcall(fn, item, ...)
    if ok then return result end
    return nil
end
```

### Item Data Quirks (discovered Session 9)

**Q22: Food hunger/thirst values are raw floats, multiply by 100 for display.**
```lua
-- Vanilla: item:getHungerChange() * 100 → integer (e.g., -0.12 → -12)
-- Vanilla: item:getThirstChange() * 100 → integer
```

**Q23: Boredom (unhappy) is NOT multiplied by 100.**
```lua
-- Vanilla uses getUnhappyChange() raw (e.g., 10.0 → +10)
-- NOT getUnhappyChange() * 100 — that gives +1000 which is wrong
-- Source: ISInventoryPaneContextMenu.lua line 2056
```

**Q24: Clothing getInsulation()/getWindResistance() DON'T EXIST on items.**
These are body-part-level calculations in ISClothingInsPanel.lua (line 425, 684).
The vanilla tooltip renders them via Java DoTooltip which has direct access.
Use only: getBiteDefense(), getScratchDefense(), getCombatSpeedModifier(), getWetness()

**Q25: Fluid container nutritional data lives on the properties chain.**
```lua
local fc = item:getFluidContainer()              -- FluidContainer object
local props = fc:getProperties()                  -- FluidProperties object
props:getHungerChange()                           -- food value (× 100 for display)
props:getThirstChange()                           -- thirst value (× 100)
props:getUnhappyChange()                          -- boredom (raw, NOT × 100)
props:getAlcohol()                                -- alcohol content
props:getCalories()                               -- nutritional: calories
props:getProteins()                               -- nutritional: proteins
props:getCarbohydrates()                          -- nutritional: carbs
props:getLipids()                                  -- nutritional: fat
-- Fluid name:
local fluid = fc:getPrimaryFluid()
fluid:getTranslatedFluidName()                    -- localized name
fluid:getFluidTypeString()                        -- internal type string
```
This chain is how Build 42 stores nutritional data for beverages.
Vanilla Lua code barely touches it — we surfaced it through safeGet probing.

**Q26: PZ Build 42 separates container items from fluid contents.**
The "Milk Carton" is the container. The cow's milk is a fluid inside it.
Category detection must check getFluidContainer() BEFORE getCategory("Food")
because fluid items may not have a "Food" category at all.

**Q27: isNoRecipes(player)/setNoRecipes(player, bool) is Java-native.**
Per-player toggle. Prevents crafting system from consuming the item.
Found at line 4567-4622 of ISInventoryPaneContextMenu.lua.

**Q28: isbDangerousUncooked() uses lowercase 'b' prefix.**
Not isDangerousUncooked() — the 'b' is part of the Java method name.
Source: ISInventoryPane.lua line 983.

**Q29: getCriticalChance() returns raw float, not integer.**
Display as math.floor(crit) .. "%" — e.g., 8.24409 → "8%"

**Q30: getCombatSpeedModifier() returns raw float.**
Display as-is (e.g., 1.0). NOT multiplied by 100.

**Q31: Fixed-size windows: set win.resizable = false BEFORE initialise().**
Disables grow box drawing and resize interaction. getBodyHeight() then returns
height - titleBarH (no grow box subtraction).

**Q32: Item card border strategy — edge flags.**
When a card is hosted inside a window, draw border on left+right+bottom only.
Top edge is covered by title bar's bottom border. Prevents double-thick line.
```lua
A.drawBorder(self, 0, 0, w, h, {top=false, right=true, bottom=true, left=true})
```

**Q33: drawStatRow ellipsis truncation.**
When stat value text overflows the available column width (after label + 8px gap),
truncate with "..." by measuring characters until they fit.

**Q34: Kahlua has no goto/labels (Lua 5.2+ feature).**
`goto skipRecipe` / `::skipRecipe::` causes parse error: `'=' expected near 'skipRecipe'`.
Fix: use a `dominated` boolean flag and wrap the inclusion in `if not dominated then`.

**Q35: Kahlua table.sort stack-overflows on large arrays.**
Kahlua's quicksort recurses O(n) deep on worst-case input. Arrays with 2000+ elements
reliably trigger `Stack overflow at Coroutine.ensureStacksize`. Even minimal closures fail.
Fix: use insertion sort with pre-computed numeric sort keys. Zero recursion, Kahlua-safe.

**Q36: Kahlua `obj:method` without () is a syntax error.**
Standard Lua 5.1 allows `obj.method` as a value (returns the function), but Kahlua
rejects `obj:method` without `()` as `function arguments expected near 'and'`.
Fix: use `obj.method` (dot syntax) for existence checks, or just pcall the call.

**Q37: pcall catches Java exceptions but Java still logs them.**
When a Java method throws inside pcall, the Lua side catches it correctly, but the
Java side logs the error to console before Lua's pcall sees it. Result: harmless but
noisy console errors. Fix: guard with Lua-side existence checks (`if item.getFullType then`)
before calling, to avoid triggering the Java error path entirely.

**Q38: ContainerButtonIcons table has gaps — many container types unmapped.**
Vanilla `ContainerButtonIcons` (shared/Definitions/ContainerButtonIcons.lua) only maps ~60 types.
Common types like `cupboard`, `overhead`, `locker`, `displaycase`, `militarylocker`, `cashregister`,
`clothingrack`, `grocerstand`, `shelvesmag` have no icon entry.
Fix: fallback lookup table mapping unmapped types to their closest vanilla alias.

**Q39: IsoDeadBody has no isFemale() — must go through getDescription().**
`isFemale()` is a player/SurvivorDesc method. Calling it on IsoDeadBody crashes.
Fix: `so:getDescription()` → `desc:isFemale()` wrapped in pcall.

**Q40: Lua `a and b or c` fails when b is nil/false (Kahlua + standard Lua).**
The ternary idiom `a and b or c` short-circuits to `c` when `b` evaluates to nil or false,
even if `a` is true. This is standard Lua behavior, not Kahlua-specific, but easy to forget.
Fix: parenthesize the fallback: `a and (b or default) or c`.

**Q41: Periodic container rebuild invalidates stored array indices.**
`buildWorldContainers()` creates a fresh array every 30 frames. Any stored indices
(like `_mcSelected` or `_activeContainer`) become stale if containers appear/disappear
or reorder. Fix: remap indices by inventory object identity after each rebuild.

**Q42: Duplicate function definitions — last-loaded file wins.**
When two files define the same function (e.g., `ZeD.Atoms.drawStatusDot` in both `Atoms.lua`
and `AtomExtensions.lua`), PZ loads files in directory order and the last definition wins at
runtime. The winning version may have a different signature than the one you're reading.
Fix: grep for all definitions of a function before calling it. Consolidate duplicates.

**Q43: Per-frame filterAndSort causes selection-triggered list jumps.**
If `filterAndSort()` runs every frame and the sort key includes data that changes on selection
(e.g., `missingCount` set by `gatherDetail` for the selected item only), the selected item
gets a different sort key than unselected items and visibly jumps in the list.
Fix: cache the sorted list. Only re-sort on explicit user actions (category, filter, pin, search).
Periodic data refreshes should NOT trigger re-sort.

**Q44: UIWorldMap.getSymbolsAPIv2() crashes on embedded instances.**
When a UIWorldMap is created as a child element (not a standalone ISWorldMap window),
the Java `uiSymbols` field is null. Calling `getSymbolsAPIv2()` throws a
NullPointerException immediately — even pcall catches it, the Java side still logs.
Fix: do not call `getSymbolsAPIv2()` on embedded UIWorldMaps. Render your own
overlay markers in the Lua `render()` method using `worldToUIX/Y` coordinates.

**Q45: Java UIWorldMap ignores ISUIElement setVisible.**
`setVisible(false)` on the Lua ISUIElement wrapper does NOT prevent the Java UIWorldMap
from rendering. The Java object has its own render pipeline that runs independently.
Fix: call BOTH `self:setVisible(false)` AND `self.javaObject:setVisible(false)`.
Also zero the element's width/height to fully prevent rendering over other content.

**Q46: PZ rendering has no blur or backdrop-filter.**
The Lua drawing API (drawRect, drawTexture, drawText, stencils) supports alpha transparency
only. No Gaussian blur, no backdrop-filter, no shader access from the modding layer.
The Java engine uses OpenGL (LWJGL) which could do blur via shaders, but this is not
exposed to Lua/modders. Use high-alpha overlays (0.97-0.98) for frosted glass effects.

**Q47: ISSearchManager.toggleSearchMode() is the canonical foraging toggle.**
`ISSearchManager.getManager(character):toggleSearchMode()` — toggles search/forage mode.
Pass `true`/`false` for explicit set, or omit for toggle. Same API used by vanilla
ISSearchWindow button, joypad radial menu, and keyboard handler. Fires events:
`onToggleSearchMode`, `onEnableSearchMode`, `onDisableSearchMode`. Manager state:
`mgr.isSearchMode` (boolean). Get manager: `ISSearchManager.getManager(character)`.
Characters always have a manager — `getManager` auto-creates if missing.

**Q48: Season-aware dawn/dusk from ClimateManager.**
`getClimateManager():getSeason():getDawn()` and `:getDusk()` return float hours (e.g., 6.5 = 6:30 AM).
These shift with season — summer has early dawn/late dusk, winter the opposite. Used by
`forageSystem.getTimeOfDay()` to determine day/night. Also useful for UI time displays.
`getClimateManager():getDayLightStrength()` returns 0–1 ambient brightness.

**Q49: Drawer stencil rects only clip during animation by default.**
Both ZeD_WorldWindow and ZeD_CharacterWindow only applied `setStencilRect` when
`effectiveW < targetW` (drawer animating open). Once fully open, the stencil was cleared.
Child panels (e.g., expanded dropdowns) could then draw beyond the drawer's boundaries.
**Fix:** Always apply `setStencilRect(0, 0, effectiveW, dh)` in the drawer prerender,
and always `clearStencilRect()` after. Restore stencil after tab renderer calls too
(renderers may change stencil state).

**Q50: forageSystem.catDefs is the post-init category table.**
`forageSystem.catDefs` (populated after `forageSystem.init()`) contains all category definitions
keyed by name string. Each catDef has: `.name`, `.categoryHidden`, `.identifyCategoryLevel`,
`.zones` (table of zone→weight), `.focusChanceMin/Max`. Filter hidden categories and check
zone weights. Translation key: `getTextOrNull("IGUI_SearchMode_Categories_"..catDef.name)`.

**Q51: ISSearchManager.spotIcon is the discovery hook point.**
`ISSearchManager:spotIcon(_icon)` fires when the player first sees a forage icon.
Icon fields: `_icon.xCoord/yCoord` (world position), `_icon.itemType` (e.g., "Base.Berry"),
`_icon.itemDef` (forageSystem definition), `_icon.iconID`. Use `ScriptManager.instance:FindItem(itemType)`
for safe display name/weight lookup — `_icon.itemObj` may be nil at spot time.
`self.player` on the manager is playerNum (integer), `self.character` is the character object.

**Q52: setStencilRect inner width must differ from outer stencil width.**
When a tab renderer calls `setStencilRect(x, y, w, h)` and the width `w` matches the
drawer's outer stencil width (set in drawer._onPrerender), `clearStencilRect` fails to
pop the stencil stack properly. The scrollbar (drawn after clearStencilRect) becomes
invisible. **Fix:** Use `contentW` (w minus scrollbarW when scrolling) instead of full `w`
for the inner stencil. This ensures the inner stencil is narrower than the outer, so
clearStencilRect pops correctly. Equipment tab always worked because it already used
`contentW`. Confirmed S74: fixed scrollbars across all 7 character tabs + 2 world tabs.
Also: ISUI3DModel cannot be a child of a stencil-using panel — the GL scissor kills
Java 3D child rendering entirely. Parent on the window instead (avatar deferred to S75).

**Q53: Never instant-set _drawerEffW for tab drawers.**
Setting `_drawerEffW = getTabDrawerW(tabId)` in the tab click handler causes a single-frame
480px width delta. PZ's Java anchor system processes this large delta before the drawer's
prerender can correct child panel positions, causing content panels to misrender.
**Fix:** Let the animation system handle the transition (small per-frame deltas via
`DRAWER_PX_SPEED * dt`). Set `_drawerOpen = true` and `_drawerMode = "tab"` — the animation
converges to `getTargetDrawerW()`. This matches the World Window pattern.
Item drawer snap (`if effW < ITEM_CARD_W then effW = ITEM_CARD_W`) is safe because 220px is small.

**Q54: addChild order = rendering Z-order (later child renders on top).**
PZ's ISPanel iterates children in addChild order during rendering. Later children draw over
earlier ones. To guarantee an overlay panel (like ITEM.DRAWER) renders on top of siblings,
add it LAST. Moving `win:addChild(itemDrawer)` after content + containerStrip fixed item card
rendering behind tab content. This matches the World Window's child ordering.

**Q55: PZ Java ISPanel enforces `minimumWidth` on `setWidth()` calls.**
`ISPanel.setWidth()` (Java side) silently clamps the value to `self.minimumWidth`. The Lua
`minimumWidth` field persists across frames — it is NOT reset each frame by the engine.
If a prerender sets `minimumWidth = 744` (e.g., `TAB_STRIP_W + drawerW + 200 + CONTAINER_STRIP_W`
while a drawer is open), and a click handler then calls `setWidth(436)`, Java clamps it to 744.
The Lua side sees `getWidth() == 744` and thinks the user resized, corrupting `_baseInvW`.
**Fix:** Always set `win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)` BEFORE
calling `win:setWidth(snapW)` in every snap site. This ensures the minimum allows the target.

**Q56: HandcraftLogic.new requires exactly 3 arguments.**
`HandcraftLogic.new(playerObj)` crashes with "expected 3 arguments, got 1". Always pass
`HandcraftLogic.new(playerObj, nil, nil)` even when no craftBench/isoObject is involved.
Same applies to `BuildLogic.new(playerObj, nil, nil)`.

**Q57: recipe:getDescription() and recipe:isNeedSurface() may not exist on all CraftRecipe types.**
Not all CraftRecipe Java objects expose these methods. Calling them throws a Java RuntimeException.
**Fix:** Check method existence with `if recipe.getDescription then` before calling. Pre-bake during
catalog build (one-time cost) rather than per-frame pcall.

**Q58: drawTextureScaledAspect does its own aspect math — never pre-scale dimensions.**
`drawTextureScaledAspect(tex, x, y, w, h, ...)` fits the texture into w×h preserving aspect ratio.
If you manually compute `dw, dh` from the texture's native size and pass those as w, h, the function
applies ANOTHER aspect-preserving shrink → double-shrink → tiny icons.
**Fix:** Always pass the bounding box size directly. Let the function handle the math.

**Q59: Kahlua pcall catches Lua errors but still logs Java RuntimeExceptions to console.**
When a pcall'd function calls a Java method that throws (e.g., method-not-found on a Java object),
Kahlua catches it for Lua flow control but the Java bridge still logs `ERROR: ... Exception thrown`
to console.txt. This spams thousands of lines per session.
**Fix:** Avoid pcalling Java methods that may not exist. Check method existence first (`if obj.methodName then`).
Pre-bake results during catalog build rather than checking per-frame.

**Q60: `ISHandcraftAction:new` calls `convertToPZNetTable(manualInputs)` which crashes on both `nil` and `false`.**
`convertToPZNetTable` (Java-side, LuaManager.java:2959) calls `.iterator()` on its argument.
Passing `nil` → Java `null` → NullPointerException. Passing `false` → `Boolean` → "expected KahluaTable, got Boolean".
Passing `{}` avoids the crash but makes `:start()` think manual inputs were selected (empty table is truthy),
so it skips auto-resolution and the craft has no items to consume — action completes but nothing happens.
**Fix:** Bypass `:new` entirely. Construct via `ISBaseTimedAction.new(ISHandcraftAction, player)` and set
all fields manually with `manualInputs = nil`. The `:start()` method checks `if self.manualInputs then` —
nil is falsy, so it takes the auto-resolve path (line 122-126) and populates items from recipe data.
Vanilla always routes through `FromLogicMultiple` which builds a real table, so this code path is never
exercised by the vanilla UI — it's a modding-only landmine.

**Q61: Script Item objects from `getPossibleInputItems()` may use `getFullName()` not `getFullType()`.**
`CraftRecipeInput:getPossibleInputItems()` returns script `Item` objects (not `InventoryItem`). These may
expose `getFullName()` (returning `"Module.Type"`) instead of `getFullType()`. `getDisplayName()` works on
both. **Fix:** Try `getFullType()` first, fall back to `getFullName()`, then manual `module:getName() .. "." .. item:getName()`.

---

## ZeD-UI ARCHITECTURE

### Design Principles (enforced)

1. **Complete UI, not a skin.** Every panel built from our component library. Zero vanilla rendering in the final product.
2. **No half-baked work.** Done = 100% working, tested, themed, responsive. Ships from disk, works from disk.
3. **Fresh every frame.** Components read ZeD.T each frame. Zero stale data on theme change.
4. **The chrome IS the design.** System 7.1.2 foundation. Hard geometry, pixel-precise borders, no softness.
5. **Two voices.** Monospace = chrome/labels. Sans-serif = content/values. Never mix.
6. **Hierarchy through caps and color.** F4 Heading = F2 Body size. ALL-CAPS + accent = heading.
7. **Own the interactions.** No ISResizeWidget, no ISScrollingListBox. Custom everything.
8. **No nested scrolling.** Design problem, not a scroll problem.
9. **Item card = recon.** Non-invasive live testing maps the PZ data model before we start replacing panels.

### Namespace
```
ZeD.T           — active theme palette
ZeD.Atoms       — draw helpers (Atoms.lua + AtomExtensions.lua)
ZeD.Molecules   — molecule draw functions + component classes
ZeD.BaseThemes, ZeD.AccentColors, ZeD.TextSizes, ZeD.Spacing — tokens
```
Organisms are global classes: ZeD_Window, ZeD_ScrollList, ZeD_TabPanel, etc.

### Theme Reactivity Pattern
```lua
function MyComponent:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    local T = ZeD.T
    o.backgroundColor = {r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = T.surf1.a}
    return o
end
function MyComponent:prerender()
    ZeD.colorSync(self.backgroundColor, ZeD.T.surf1)  -- mutate in-place, zero alloc
    ISPanel.prerender(self)
end
```

### Token System (ZeD.T)
Surfaces: base, surf1-4. Borders: border (soft), borderS (strong).
Text: text, textSec, textHead. Accent: accent, accentBright, hover, textOnAccent.
Status: danger, warning, positive, info.
Fonts: fontF1 (Chrome/Fira Mono Bold), fontF2 (Body/Fira Sans Cond.), fontF3 (Data/Fira Mono), fontF4 (Heading/Fira Sans Cond. SemiBold), fontF5 (Micro/Fira Sans Cond. 9px).
Dimensions: titleBarH, rowH, buttonH, tabH, inputH, fillBarH.
Spacing: T.sp.sm, T.sp.md, T.sp.lg, T.sp.xl, T.sp.scrollbarW.

### Utility Functions
```lua
ZeD.colorAlpha(color, alpha)        -- new table with modified alpha
ZeD.colorBlend(base, overlay, s)    -- lerp between two colors
ZeD.colorSync(target, source, aOvr) -- mutate target in-place (zero alloc)
ZeD.applyTheme(base, accent, sz)    -- rebuild ZeD.T
```

---

## ITEM CARD ARCHITECTURE

### Category Detection Order
```lua
1. getFluidContainer() ~= nil → "Fluid"     (MUST be first — fluid items may not be "Food")
2. instanceof HandWeapon + getAmmoType → "Firearm"
3. instanceof HandWeapon → "Weapon"
4. getCategory() == "Food" → "Food"
5. getCategory() == "Clothing" → "Clothing"
6. instanceof DrainableComboItem → "Drainable"
7. getCategory() == "Literature" → "Literature"
8. getItemCapacity() > 0 → "Container"
9. instanceof Key → "Key"
10. canEmitLight() → "Light"
11. fallback → "Item"
```

### Status Alerts (badges below item name)
Broken, Wet (>15), Rotten, Burnt, Frozen, Tainted, Activated, Equipped, Favorite, Bloody, Dirty, Raw! (dangerous uncooked)

### Layout: About This Macintosh
```
┌──────────────────────────────────────────────┐
│ [icon] Item Name    : STAT LABEL    Value    │
│        [alerts]     : STAT LABEL    Value    │
│                     : STAT LABEL    Value    │
│ CATEGORY   type     : WEIGHT        X.X kg   │
│─────────────────────────────────────────────│
│ CONDITION      82%  : [████████████████░░]   │
└──────────────────────────────────────────────┘
```
- 50/50 columns, 12px gap, no vertical divider
- Icon: no box, texture breathes on its own
- Card has no top border (title bar covers it)
- Fixed-size window (resizable=false), auto-height from calcHeight()
- Values truncated with "..." if they overflow column width

---

## COMMON MISTAKES TO AVOID

1. `ZeD.Atoms = {}` unconditionally — use `ZeD.Atoms = ZeD.Atoms or {}`
2. Allocating color tables in prerender() — allocate once in new(), mutate via colorSync()
3. Calling item:getInsulation() — doesn't exist on items, body-part-level only
4. Multiplying boredom by 100 — getUnhappyChange() is already in display scale
5. Using tostring(float) for display — gives 15-digit precision, use math.floor() or string.format()
6. Drawing card border on all 4 edges inside a window — double-thick top line
7. Trusting getCategory("Food") for fluid containers — check getFluidContainer() first
8. Using getCombatSpeedModifier() * 100 — raw value is already the display value
9. Scrollbar reserveBottom when parent excludes grow box — double subtraction
10. Relying on onMouseDown alone — children eat events, use update() as backup
11. Adding `or` fallbacks — ZeD.T is always populated, trust the token system
12. Centering stats vertically without clamping — overflows into footer at large font
13. ISPanel child panels render independently of parent stencil rects — children draw outside clipped area when scrolled. Use direct `drawAt()` rendering instead of `addChild()` for scroll-clipped content.
14. BodyPartType enum names differ from CharInfoOverhaul conventions — vanilla uses `UpperArm_L`/`ForeArm_L`/`Hand_L` not `Arm_Upper_Left`/`Arm_Lower_Left`/`Hand_Left`. Verify against ISHealthPanel.lua.
15. Thermoregulator `getNode(i)` + `getName()` string matching is unreliable — use `getNodeForType(BodyPartType)` (vanilla ISClothingInsPanel pattern). All `*UI` getter variants return 0-1 normalized values for display.
16. Lua `local function` is only visible AFTER its declaration line — forward references to local functions cause "call nil" errors. Declare helpers before the functions that call them.
17. `wornItem:getLocation()` returns group-prefixed strings like `"base:tshirt"`, `"base:pants"`, `"base:belt"` — NOT plain PascalCase like `"Tshirt"`. Strip the `"group:"` prefix before matching. ForageSystem's `clothingPenalties` table uses unprefixed PascalCase keys because it was written before groups were added to body locations.
18. Forward-referencing `local` variables in closures — a function defined BEFORE a `local x = ...` line cannot capture `x`. The closure sees global `x` (nil). Fix: forward-declare with `local x` before the function, assign later (see Settings.lua S64 fix).
19. Embedded UIWorldMap `setVisible(false)` doesn't hide Java rendering — must also call `javaObject:setVisible(false)` AND zero dimensions. Without all three, the Java map renders over other Lua-drawn content.

---

## B42 CRAFTING API (discovered Session 49)

### HandcraftLogic — the data layer for crafting UI
```lua
-- Create logic instance (same pattern Neat Crafting uses)
local logic = HandcraftLogic.new(player, craftBench, isoObject)
logic:setManualSelectInputs(true)

-- Event listeners — the core API for reactive UI
logic:addEventListener("onUpdateRecipeList", callback, context)  -- recipe list rebuilt
logic:addEventListener("onRecipeChanged", callback, context)     -- selected recipe changed
logic:addEventListener("onInputsChanged", callback, context)     -- ingredient availability changed
logic:addEventListener("onShowManualSelectChanged", callback, context)
logic:addEventListener("onRebuildInputItemNodes", callback, context)
logic:addEventListener("onStartCraft", callback, context)        -- crafting begins
logic:addEventListener("onStopCraft", callback, context)         -- crafting ends

-- Recipe access
logic:setRecipe(craftRecipe)          -- select a recipe
logic:getAllBuildableRecipes()        -- returns Java list of buildable recipe elements
-- Each element: element:getCraftRecipe() → craftRecipe object
-- craftRecipe:getTags() → Java list of tag strings (first tag = category)
-- craftRecipe:getTranslationName() → localized display name
-- craftRecipe:getIconTexture() → icon texture
```

### ISHandcraftWindow — the vanilla crafting window wrapper
```lua
-- Opens via ISEntityUI.OpenHandcraftWindow(player, nil, "*", false, craftRecipe)
-- ISHandcraftWindow:derive("ISHandcraftWindow") from ISCollapsableWindow
-- Creates ISHandCraftPanel (the PZAPI node-based inner panel)
-- recipeQuery default: "InHandCraft;AnySurfaceCraft"
-- Lock button for position persistence
-- calculateLayout handles responsive sizing (the source of the "too big" bug)
```

### BuildUI.lua — PZAPI node-based crafting interface
```lua
-- Uses PZAPI.UI declarative node system (NOT ISUI)
-- 14 categories filtered by craftRecipe:getTags():get(0):
-- All, Favourite, Animal, Blacksmithing, Carpentry, Demo, Farming,
-- Masonry, Metalwork, Outdoors, Pottery, Stonemasonry, Survival, Welding
-- Category icons are item textures (e.g., Item_Anvil_Forged.png for Blacksmithing)
-- 48×48 category buttons, 320×320 item buttons (scaled 0.25)
```

### Key B42 crafting API limitation
The new `craftRecipe` system is significantly harder to mod than B41's Recipe system.
Adding items to existing recipe inputs requires accessing Java's cached `loadedItems`
field through `testFunction` workarounds. PZwiki explicitly calls for TIS to implement
proper modification methods. Any crafting UI replacement must work with the existing
recipe data — don't try to modify recipes from Lua.

### Animal API (discovered Session 84)

**Q62: Animal hunger is on the Stats object, NOT getData().**
```lua
-- WRONG: animal:getData():getHunger()     -- does not exist
-- RIGHT: animal:getStats():get(CharacterStat.HUNGER)  -- returns 0.0–1.0
-- Thirst has a direct shortcut: animal:getThirst()     -- returns 0.0–1.0
-- Multiply by 100 for display percentage.
```

**Q63: animal:getAnimalType() returns lowercase engine strings.**
Used with `getText("IGUI_AnimalType_" .. type)` for display names. Values include: cow, bull, ewe, ram, chicken, rooster, hen, pig, sow, boar, turkey, turkeyhen, rabbit, raccoon, deer, stag, doe, fawn, etc.

**Q64: Kahlua chained `and` with method calls causes parse errors.**
```lua
-- CRASHES: local x = getGameTime and getGameTime():getCalender and getGameTime():getCalender()
-- FIX: break into sequential nil checks:
local gt = getGameTime and getGameTime()
if not gt or not gt.getCalender then return end
local cal = gt:getCalender()
```

**Q65: attackOtherMales() is the engine flag for male-on-male aggression.**
Don't manually count adult males per species — use `animal:attackOtherMales()` to check if an animal has the aggression trait, then verify another adult male of the same type exists in the zone.

**Q66: Java proxy objects from DesignationZoneAnimal.getAllZones() lose Lua table key identity.**
Each call to `getAllZones()` returns fresh Lua proxy wrappers for the same underlying Java zone objects. Using these as Lua table keys (`cache[zone] = summary`) breaks on the next call because the new proxy `~=` the old one. **Fix:** Cache by zone name string, not object reference. Store zone names in state, look up fresh proxies via helper:
```lua
local function getZoneByName(name)
    local allZones = DesignationZoneAnimal.getAllZones()
    for i = 0, allZones:size() - 1 do
        local z = allZones:get(i)
        if z:isStillStreamed() and z:getName() == name then return z end
    end
    return nil
end
```

**Q67: screenToIsoX/Y for mouse-to-world coordinate conversion.**
`getMouseWorldX()` / `getMouseWorldY()` do NOT exist. Use:
```lua
local wx = screenToIsoX(playerNum, getMouseX(), getMouseY(), z)
local wy = screenToIsoY(playerNum, getMouseX(), getMouseY(), z)
local sq = getCell():getGridSquare(wx, wy, z)
```
Same API used by vanilla `ISAddDesignationAnimalZoneUI:pickSquare()`.

**Q68: ISAddDesignationAnimalZoneUI requires parentUI reference.**
`ISAddDesignationAnimalZoneUI:new(x, y, w, h, player)` stores a `parentUI` reference set externally after creation. The `undisplay()` method calls `self.parentUI:setVisible(true)` — crashes with nil index if parentUI was never set. **Fix:** Don't open this panel standalone. Build custom zone creation UI instead, using `DesignationZoneAnimal.new()` directly.

**Q69: DesignationZoneAnimal.removeZone(zone, flag) — flag is remove-fence.**
The second parameter to `removeZone` is NOT "remove connected zones." It's a fence-cleanup flag. Vanilla always passes `true` and removes one zone correctly. If removing all zones, the bug is in zone identity (Q66), not in this parameter.

**Q70: Tab icon PNGs must be 8-bit depth — PZ throws IOException on 16-bit.**
PZ's texture loader (`FileSystemImpl.updateAsyncTransactions`) calls `ImageIO.read()` which rejects
16-bit PNGs with `Unsupported bit depth: 16`. `getTexture()` then returns nil silently.
ImageMagick's `-depth 8` flag converts: `magick input.png -depth 8 output.png`.
All custom icon PNGs (especially GrayscaleAlpha from batch inversion) must be verified 8-bit.

**Q71: ISUI3DModel doesn't need strict viewport boundary checks.**
Window-parented ISUI3DModel children are clipped by the ISCollapsableWindow's own rendering
boundaries (Java side). Manual Lua checks like `avatarY >= top and avatarY + h <= bot` are
overly strict and cause the model to disappear prematurely or require scroll-to-show.
**Fix:** Just clamp Y below the pinned tab header (`bY + tabHeaderH`) and let the window clip.
The Q52 stencil issue only applies to stencilRect-using PANELS, not to window-level children.

**Q72: World Window onMouseWheel must route to tab-specific handlers.**
The drawer's `onMouseWheel` dispatches to `getWorldActiveScroll()` by default, which returns
the tab's main scroll. But CraftingTab and BuildingTab have dropdown overlays with their own
scroll logic in `CC.onMouseWheel()`. If the wheel event bypasses this, dropdown scroll breaks.
**Fix:** Check `win._activeTab == "craft"/"build"` before falling through to generic scroll,
and delegate to `ZeD.CraftingTab.onMouseWheel()` / `ZeD.BuildingTab.onMouseWheel()`.

### Context Menu System (S88 — discovered building unified menu)

**Q73: ISContextMenu is a per-player CACHED SINGLETON, not a per-RMB instance.**
Each call to `ISContextMenu.get(player, x, y)` returns the SAME instance for that player
via `getPlayerContextMenu(player)`. The instance is added to UIManager ONCE at first use
and then reused across every subsequent RMB. `setVisible(true)` and `clear()` drive the
per-RMB lifecycle, NOT `addToUIManager`. Hooking `addToUIManager` to intercept menu
spawning will only fire ONCE per session — not what you want.

**Q74: prerender is the reliable per-RMB intercept point on the singleton menu.**
Combined with `clear()` as the per-RMB reset signal, this is the working pattern:
```lua
local origClear = ISContextMenu.clear
function ISContextMenu:clear()
    origClear(self)
    self._zedSpawned = false   -- reset per-RMB marker
end

local origPrerender = ISContextMenu.prerender
function ISContextMenu:prerender()
    if self._zedSpawned then self:setX(-100000); return end
    if self.addDefaultOptions then pcall(function() self:addDefaultOptions() end) end
    if self:isEmpty() then self._zedSpawned = true; return origPrerender(self) end
    self._zedSpawned = true
    -- ... build replacement menu, hide vanilla off-screen, skip orig prerender
end
```
First prerender frame after `clear()` has fully-populated `.options` from the OnFill events.

**Q75: Removing the singleton ISContextMenu from UIManager breaks ALL future RMBs.**
Vanilla never re-adds the per-player singleton. If a derivative menu's `close()` calls
`vanillaMenu:removeFromUIManager()` to "clean up", subsequent RMBs will silently fail —
`ISContextMenu.get()` returns the cached instance, `setVisible(true)` flips the flag,
but the panel isn't in UIManager so `prerender()` never fires. To dismiss, use
`setVisible(false)` and/or `setX(-100000)`. Never remove the cached singleton.

**Q76: setStencilRect takes panel-LOCAL coordinates directly.**
Common bug: subtracting the panel's x/y from the desired stencil position (treating it
as a relative offset). Don't. `panel:setStencilRect(x, y, w, h)` clips to the rectangle
at panel-local `(x, y)` — the SAME coordinate space the molecules pass to draw calls.
A mismatched stencil silently clips ALL drawing to a tiny rectangle near panel origin
and produces a "panel renders nothing" symptom with no error.

**Q77: ISWorldObjectContextMenu.checkWeapon(chr) is misleadingly named.**
Despite the name, this is a weapon-presence check on a character — it does NOT trigger
or open a context menu. It returns true/false based on whether `chr` has a usable weapon.
Useful for action gating; useless for any "fire a fresh world RMB programmatically"
intent. The actual programmatic entry is `ISContextManager.getInstance().createWorldMenu(
playerNum, nil, worldobjects.items, x, y)` — but you must build the worldobjects list
yourself (PZ's mouse handler does it from Java; no clean Lua picker exists at the time
of writing).

**Q78: Vanilla "More" submenus are overflow buckets — flatten them for strip menus.**
`ISInventoryPaneContextMenu.lua:4659` wraps Rename / Show Build Recipes Used /
Rename Bag / Rename Food / debug actions inside a submenu titled `getText("ContextMenu_More")`.
This makes sense for vanilla's vertical dropdown but adds a navigation level that's noise
for icon-strip menus that handle overflow via truncation/scroll. Detect any top-level
option whose `.name == getText("ContextMenu_More")` (or unlocalized "More") that has
`.children` and splice the children into the parent list at that position.

**Q79: PZ bitmap fonts have ASCII but lack `›` (U+203A) and similar Unicode glyphs.**
Breadcrumb separators using `›` render as tofu or blank. Q15b documented arrow glyph
absence; same root cause applies to typographic punctuation. Use plain ASCII ` > ` as
a separator and accept the visual compromise — it's a known PZ bitmap-font limitation.

**Q80: PZ joypad dispatch is duck-typed — no ISPanelJoypad inheritance required.**
`joypadData.focus:onJoypadDown(button, joypadData)` — no instanceof check against
`ISPanelJoypad` or `ISUIElementJoypad`. Any ISPanel subclass implementing the method
signatures (`onJoypadDown`, `onJoypadDirUp`, `onJoypadDirDown`, `onJoypadDirLeft`,
`onJoypadDirRight`) will receive dispatch. **Implication:** `ZeD_Panel` does NOT need
`ISPanelJoypad` inheritance. Stub methods on the base class, delegate to FocusManager.
Saves an inheritance chain and avoids coupling to vanilla's gamepad class hierarchy
(which has its own history of B42 patch churn). Confirmed S89 research for GAMEPAD_SPEC.

**Q81: `wasMouseActiveMoreRecentlyThanJoypad()` is unreliable — don't use it.**
Vanilla helper returns stale values and does not distinguish mouse movement from mouse
clicks. Returns true even after the player has been on gamepad for minutes, simply
because the cursor moved a pixel. **Fix:** implement custom input mode detection per
the Jibb Smart rule — mouse clicks and keyboard presses count as KBM activity; mouse
movement alone does NOT. Canonical implementation: `InputModeDetector.lua` (stick
threshold 0.20, trigger threshold 0.15, 200ms cooldown between mode switches). Do not
consume `wasMouseActiveMoreRecentlyThanJoypad()` anywhere in ZeD-UI.

**Q82: Character gameplay controls are locked in Java — not rebindable from Lua.**
Movement, aim, attack, sprint, crouch — all gameplay bindings are wired in Java engine
code and cannot be rebound from Lua. Confirmed by Custom Gamepad UI (B42.16) mod
author. **Implication:** ZeD-UI gamepad scope is UI navigation only. Gameplay control
fixes (e.g., B42.16's pressure-sensitive aim regression, the can't-move-with-inventory
bug) require Java source modification, which is out of mod scope. Mitigation strategy
ZeD-UI does adopt: ensure the mod itself doesn't worsen these issues — GAMEPAD_SPEC D1
("movement never blocked") + windowshade-on-LS/RS/LT dismiss model directly counter
the can't-move-with-inventory regression by guaranteeing UI steps aside on gameplay
input.

**Q83: B42.16 controller overhaul introduced regressions — design around them, not on them.**
Build 42.16 shipped (a) pressure-sensitive aim triggers that activate from resting
finger pressure and (b) a can't-move-with-inventory-open bug. **Implication for ZeD-UI:**
never trap the player in a menu; always allow gameplay input to reflexively dismiss UI.
GAMEPAD_SPEC's D1 ("movement never blocked") and the locked dismiss model (LS/RS/LT
magnitude > 0.20 → windowshade + release focus) are the architectural response — both
directly address this class of regression. Every new ZeD-UI gamepad feature must honor
these rules; any future PZ patch that regresses gameplay input must not cascade into
ZeD-UI blocking the player.

**Q84: `getCore():doZoomScroll(playerIdx, direction)` is the Lua-callable zoom API.**
`direction` is an integer: positive = zoom-IN (closer to player), negative = zoom-OUT
(further from player). One call = one zoom step of 0.25 units. Matches mouse wheel
semantics directly — in `DebugChunkStateUI.lua:298` the wheel delta is passed straight
through without inversion. `playerIdx` is 0-based; pass `0` for single-player, or the
actual player index for split-screen. Vanilla call sites:
```lua
-- client/Tutorial/Steps.lua:1196-1198 (tutorial sneak step, hardcoded playerIdx=0)
getCore():doZoomScroll(0, 1)   -- zoom in
getCore():doZoomScroll(0, -1)  -- zoom out

-- client/ISUI/ISBackButtonWheel.lua:160-162 (vanilla gamepad zoom in back-button wheel)
getCore():doZoomScroll(self.playerNum, 1)
getCore():doZoomScroll(self.playerNum, -1)
```
Current zoom level readable via `getCore():getZoom(playerIdx)` (returns float). No
`setZoom()` on core — if you need absolute zoom, loop `doZoomScroll` against the
current vs target delta. Respects `getCore():getAutoZoom(playerIdx)` flag (the vanilla
gamepad zoom wheel guards against calling when auto-zoom is on). Confirmed functional
during ZeD-UI S92 BumperChord QA — 35 successful zoom dispatches, zero exceptions, no
`pcall` failures. Works while game is paused (operates on `IsoCamera` directly). Not
rate-limited at the call site; spam-safe per-frame. Used by BumperChord.lua wrapped
in `pcall` for signature-drift safety.

**Q85: Top-level `print()` at Lua file-load time is NOT captured in console.txt on B42.16.**
Runtime event-callback prints (from `Events.OnTick`, `Events.OnGameStart`,
`Events.OnMouseDown`, custom event handlers, etc.) DO appear in `console.txt`.
Top-level prints — those that execute during PZ's initial Lua file-load pass,
before/during the logger stream being wired up — go to stdout only. **Observed in
S91/S92:** Both `[ZeD.Input] InputModeDetector loaded - awaiting first input event`
and `[ZeD.Input] BumperChord loaded - no arming timeout, hold-and-tap model` are
absent from `C:\Users\danie\Zomboid\console.txt` despite both files definitely loading
(their runtime `Events.OnTick` handlers fire correctly and their state transitions
appear in console.txt). **Workaround** if you need a boot-diagnostic to be grep-able:
wrap the `print()` in an `Events.OnGameStart.Add(function() print(...) end)` callback.
That fires after PZ's logger is fully wired, and the line ends up in console.txt. For
purely top-level prints, accept they're stdout-only and don't rely on them for QA.
Does NOT affect `isoConsole`-style in-game console output — that's a separate pipeline.

**Q86: ZeD_Window derives from ISPanel DIRECTLY — NOT from ZeD_Panel. Base-class contracts must be duplicated on both classes.**
Inheritance chain verified via grep S93:
```lua
-- Organisms.lua:38
ZeD_Window = ISPanel:derive("ZeD_Window")       -- NOT ZeD_Panel:derive

-- ZeD_Panel.lua:18
ZeD_Panel = ISPanel:derive("ZeD_Panel")

-- ZeD_ContextMenu.lua:29
ZeD_ContextMenu = ZeD_Panel:derive("ZeD_ContextMenu")   -- the ONE subclass of ZeD_Panel
```
The name `ZeD_Panel` is misleading — it reads as "the base for all ZeD UI surfaces" but in practice only `ZeD_ContextMenu` actually uses it. `ZeD_Window` (Character Window, World Window, standalone inspect, any future ZeD window type) bypasses it entirely. **Implication:** any method intended as a "ZeD UI surface contract" (onJoypadDown, onJoypadDir*, future onGamepadConnect, theme-reactivity hooks, lifecycle callbacks) must be duplicated onto BOTH `ZeD_Panel` AND `ZeD_Window`, OR `ZeD_Window` must be refactored to `ZeD_Panel:derive`. S93 chose duplication for minimum blast radius. Future Organisms.lua refactor candidate: change `ZeD_Window = ISPanel:derive(...)` to `ZeD_Window = ZeD_Panel:derive(...)` and let ZeD_Window inherit the existing ZeD_Panel methods (hit zone registry, _onPrerender hook, joypad stubs). Risk is the `setmetatable(o, self)` + `self.__index = self` pattern in `ZeD_Window:new()` conflicting with ZeD_Panel's — worth a careful read-through but mechanically simple. **Grep for future work:** check all current `ZeD_Window:method()` definitions for collision with ZeD_Panel methods before flipping the derive call.

**Q87: `setJoypadFocus(playerID, control)` is the canonical engine-level joypad focus setter — without it, `onJoypad*` dispatch never routes to your element.**
PZ's engine dispatches `joypadData.focus:onJoypadDown(button, joypadData)` — the focus target is stored as `joypadData.focus`. Mod-local state (tracking "my window has focus" in a Lua table) is INVISIBLE to the engine unless you push the same target into `joypadData.focus`. Defined at `shared/JoyPad/JoyPadSetup.lua:459`:
```lua
-- Canonical usage
setJoypadFocus(0, myWindow)   -- player 0, focus on myWindow
setJoypadFocus(0, nil)         -- release focus; vanilla input resumes
```
Related globals: `getJoypadFocus(playerID)` reads current; `setPrevFocusForPlayer(playerID)` restores the previous focus in a 3-deep chain (`focus / prevfocus / prevprevfocus`).
**Failure mode S93 shipped with:** we updated our `_focusedWindow` state and logged "Focus: claim: ... → ..." but never called `setJoypadFocus`. Joypad face-button presses went to whatever target held vanilla focus (usually nil). Our shims were dead code. "QA-clean zero crashes" was actually zero-dispatch — the safer interpretation was "dispatch never fired", not "dispatch fired silently".
**Fix (S94):** every `claimFocus` calls `setJoypadFocus(0, w)`; every `releaseFocus` calls `setJoypadFocus(0, nil)`; `unregisterWindow` transfer path calls it on the survivor. S95 kept this wiring. playerID hardcoded to 0 for SP; split-screen threads per-window playerNum through later.

**Q88: `ISButtonPrompt:onYPress` is the vanilla gamepad Y-opens-inventory path — override the METHOD (not `cmdShowInventory`).**
When gamepad Y is pressed and `joypadData.focus == nil` (e.g., just after our windowshade released focus), the engine dispatches through `JoypadControllerData:onPressButtonNoFocus(button)` which calls `buts:onYPress()` on the player's `ISButtonPrompt`. Vanilla `onYPress` reads `self.yFunc` — cached via `setYPrompt(label, ISButtonPrompt.cmdShowInventory, nil)` as a DIRECT function reference — and fires it, showing the vanilla inventory panel.
**Trap:** overriding `ISButtonPrompt.cmdShowInventory = newFn` does NOT take effect, because `setYPrompt` copied the OLD function reference into `self.yFunc` at bind time. The existing prompt instance still calls the old `cmdShowInventory`.
**Fix:** override `ISButtonPrompt.onYPress` itself on the class table. Method lookup is via metatable chain at call time, so the replacement resolves instantly:
```lua
if ISButtonPrompt then
    ISButtonPrompt.onYPress = function(self) end  -- no-op; route Y through own FocusManager
end
```
Same pattern applies to `onXPress` / `onBPress` / `onAPress` / `onLBPress` / `onRBPress` if you need them. Vanilla drag handlers (`setYPrompt(getCell():getDrag(self.player):getYPrompt(), nil)` at line 768) pass `nil` as the func, so a no-op override doesn't break drag behavior either.

**Q89: `joypadData.controller` is a Lua `JoypadControllerData` table — NOT a numeric controller index — and `getControllerAxisValue` wants the int index.**
`getControllerAxisValue(ctlIdx, axisIdx)` expects two integers. `joypadData.controller` looks like it would be the right argument but is actually a `JoypadControllerData:derive(ISBaseObject)` instance — a Lua table. Passing it crashes with:
```
java.lang.RuntimeException: expected argument of type int, got KahluaTableImpl
```
**Correct pattern** (mirrors `InputModeDetector.anyGamepadActive`):
```lua
local n = (getControllerCount and getControllerCount()) or 0
for ctlIdx = 0, n - 1 do
    if isControllerConnected and isControllerConnected(ctlIdx) then
        local lx = getControllerAxisValue(ctlIdx, 0) or 0   -- AXIS_LSTICK_X
        local ly = getControllerAxisValue(ctlIdx, 1) or 0   -- AXIS_LSTICK_Y
        -- etc.
    end
end
```
`joypadData.controller` is useful for its own methods (e.g., `controller:clearJoypad()` at JoyPadSetup.lua:71) but NEVER as an axis-read argument. `joypadData.id` is an integer (the joypad ID) and IS valid for `isJoypadPressed(jid, btn)`.

**Q90: `math.abs()` on trigger axis reads is WRONG for "pull detected" semantics — it turns the at-rest value of Xbox/PS drivers (`-1`) into `+1`, firing constantly.**
PZ's `getControllerAxisValue(ctlIdx, AXIS_LTRIGGER)` reports trigger state in one of two driver conventions:
- `[0, 1]`: rest = 0, fully pulled = 1. Raw `v > threshold` detects pull cleanly.
- `[-1, 1]`: rest = -1, fully pulled = +1. (Common on Xbox/PS drivers.) Here `abs(-1) = 1`, so any threshold test with `abs()` reads "always pulled" at rest.
**Trap (S95 shipped, caught in v2 via diagnostic print):** `math.abs(lt) > tt` fires windowshade every tick on `[-1, 1]` drivers. First shade latches forever; subsequent reopens instantly re-shade.
**Correct pattern for pull detection:**
```lua
local lt = getControllerAxisValue(ctlIdx, AXIS_LTRIGGER) or 0   -- no abs()
if lt > triggerThresh then ... end  -- rest=-1 fails, rest=0 fails, pull>0 passes
```
Works for BOTH driver conventions because both normalize to `>0` only on actual pull.
**Where `abs()` IS acceptable:** `InputModeDetector`'s mode-detection path — "is any trigger showing activity, including the at-rest `-1` which proves a gamepad is plugged in." For mode detection, constant `|lt|>0.15` keeps the gamepad detected; for shade-on-pull, it's a false positive every tick.
Stick magnitude reads (`sqrt(lx² + ly²)`) are NOT affected by this trap — sticks rest near `(0, 0)` on both conventions and `sqrt` is always non-negative anyway.

**Q91: Java objects (InventoryItem, etc.) do NOT support arbitrary Lua field assignment — `item._myField = value` throws "attempted index of non-table" at runtime.**
PZ items returned by `inventory:getItems():get(i)` are Java objects wrapped by Kahlua as `KahluaTableImpl`-adjacent but NOT actual Lua tables. Attempting to set an arbitrary field (`item._zedRenderY = y`) crashes with:
```
java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:99)
se.krka.kahlua.vm.KahluaThread.tableSet(KahluaThread.java:1474)
```
**Correct pattern:** Use a Lua-side map table keyed by the Java object reference:
```lua
local myMap = {}
myMap[item] = someValue   -- Java object as key is fine
local v = myMap[item]     -- lookup works; Java object identity is stable
```
Java objects work as table KEYS (identity-based lookup) but NOT as table-like containers for arbitrary field writes. This applies to all Java-bridged objects in PZ (items, containers, body parts, etc.), not just InventoryItem.
Discovered S96 when `item._zedRenderY = y` crashed in InventoryRenderer.lua drawItemRow. Fixed by using `self._itemRenderYMap[item] = y` instead.

**Q92: Vanilla context submenus live in `instanceMap` via `:getSubMenu(num)` — NOT `.subMenus[num]`.**
ISContextMenu's submenu storage is not an obvious field. `ISContextMenu:addSubMenu(option, menu)` just sets `option.subOption = menu.subOptionNums` (a numeric key). The actual submenu panel is stored on the PLAYER'S CACHED TOP-LEVEL MENU under `context.instanceMap[subOptionNums]`, reached via the public API `ISContextMenu:getSubMenu(num)` which internally does `getPlayerContextMenu(self.player):getSubInstance(num)` (see `ISContextMenu.lua:1225`). There is no `.subMenus` field.
**Trap (S99 shipped, caught in QA):** Our ContextMenuRegistry.makeActionDef was reading `vanillaMenu.subMenus[option.subOption]` — a non-existent field — so `def.children` was never populated for submenu parents (Move to, Fix, Rename, clothing actions). Every drill-in hit the "leaf" path in confirm(): if the parent had `onSelect` (rare for submenu parents) it fired; otherwise the menu silently closed. User saw "menu disappeared instead of drilling in."
**Correct pattern:**
```lua
if option.subOption and vanillaMenu and vanillaMenu.getSubMenu then
    local ok, sub = pcall(function() return vanillaMenu:getSubMenu(option.subOption) end)
    if ok and sub and sub.options and #sub.options > 0 then
        def.children = {}
        for j, subOpt in ipairs(sub.options) do
            def.children[#def.children + 1] = makeActionDef(subOpt, j, sub, target)
        end
    end
end
```
**Lazy-populate escape hatch:** Some mods populate submenu options only when the user hovers (via `option.onSubMenu(vanillaMenu, option)`). Gamepad users never hover. At drill-in time, if children is still empty and `option.onSubMenu` exists, fire it in pcall and re-read the submenu before drilling.

**Q93: `ISInventoryPaneContextMenu.onDropItems` / `onGrabItems` take player INDEX (int), not IsoPlayer object.**
Signature is `function(items, player)` where `player` is an integer 0-3. Vanilla internally calls `getSpecificPlayer(player)` and `getPlayerInventory(player)` which require int args (Java-bridge boundary). Passing an IsoPlayer object throws:
```
java.lang.RuntimeException: expected argument of type int, got IsoPlayer
  at MethodArguments.assertValid(MethodArguments.java:128)
```
The Lua caller's `pcall` catches it silently, but the action never runs. Console.txt logs the Java exception + `Lua(Vanilla).onDropItems> Exception thrown`.
**Correct pattern:**
```lua
pcall(ISInventoryPaneContextMenu.onDropItems, {item}, 0)   -- int
```
NOT:
```lua
local playerObj = getSpecificPlayer(0)
pcall(ISInventoryPaneContextMenu.onDropItems, {item}, playerObj)   -- WRONG — throws
```
Discovered S99 when gamepad X-drop/grab bindings silently failed. Same trap applies to any vanilla inventory helper that uses `getSpecificPlayer()` internally — always check whether the signature expects the index or the object.

**Q94: `ItemContainer.new(type, nil, nil)` with no IsoObject parent silently no-ops vanilla transfer/wear/equip actions.**
Virtual `ItemContainer` instances (e.g., the World Window's `_floorContainer` that aggregates ground items from a 3×3 square into one list) have no IsoObject parent. When vanilla code builds an `ISInventoryTransferAction` with this container as source, the action has no IsoGridSquare to walk the player toward → Java-side validation silently drops the action without queueing. `pcall` around the vanilla `onSelect` returns OK because no Lua exception was thrown — but nothing happens. This affects:
- `ISInventoryPaneContextMenu.onGrabItems` (Grab option)
- `ISInventoryPaneContextMenu.onWearItem` / `ISWearClothing` (Wear/Equip option)
- Any "Move to X" options that use `ISInventoryTransferAction`
- Anything else that routes through `ISInventoryTransferAction`
**Fix (S100):** pre-transfer floor items into the player's real inventory BEFORE the vanilla `onSelect` fires. `ContextMenuRegistry.makeActionDef`'s `def.onFire` now detects if `selfArg` (the items array) contains items whose container is the floor, and routes them through the existing `ZeD_WorldWindow.transferFromFloor(playerObj, item, playerInv)` helper (raw world-object removal + `AddItem`). After the pre-transfer the items are in a real container with a real IsoObject parent, so the subsequent vanilla action proceeds normally.
```lua
-- In makeActionDef, before pcall(option.onSelect, ...):
local ZWW = ZeD_WorldWindow
local floor = ZWW and ZWW.getFloorContainer and ZWW.getFloorContainer()
if floor and ZWW.transferFromFloor and type(selfArg) == "table" then
    local playerObj = getSpecificPlayer(0)
    local playerInv = playerObj and playerObj:getInventory()
    if playerInv then
        for i = 1, #selfArg do
            local it = selfArg[i]
            if it and it.getContainer and it:getContainer() == floor then
                pcall(ZWW.transferFromFloor, playerObj, it, playerInv)
            end
        end
    end
end
-- Then call option.onSelect as usual — items are now in playerInv.
```
The same pattern applies to any future "virtual aggregation container" that hosts items sourced from real world objects. Diagnostic pattern: if a vanilla action fires cleanly in a pcall but nothing visibly happens, check whether the source container has a `nil` IsoObject parent. Also: for Grab specifically, the pre-transfer IS the grab — vanilla's subsequent call is a harmless no-op because items are already where it wanted to put them.

**Q95: Per-frame focusable builders that write `_gpFocused*` seed values stomp live D-pad onFocus writes.**
When a builder function (e.g., `_buildEquipmentFocusables`, `_buildHealthFocusables`, `_buildThermalFocusables`, `_buildSkillsFocusables`) runs inside the per-frame ring refresh and has a tail block like `if elements[1] then win._gpFocused* = elements[1].slotType`, it OVERWRITES whatever the D-pad `onFocus` callback just wrote. Symptom: user D-pads, visual fill flashes on the focused element for one frame, then "resets" back to the first element on every subsequent frame. The per-frame builder re-runs → seed line fires → overwrites.
**Fix (S100):** guard the seed on nil — it becomes a true one-shot initial seed, not a per-frame overwrite.
```lua
-- BAD — stomps every frame:
if elements[1] then win._gpFocusedEquipSlot = elements[1].slotType end

-- GOOD — seeds only when unset (mode entry / tab switch cleared it):
if elements[1] and win._gpFocusedEquipSlot == nil then
    win._gpFocusedEquipSlot = elements[1].slotType
end
```
Then when changing modes (card entry, tab switch, etc.), explicitly clear the field: `w._gpFocusedEquipSlot = nil` in the transition code. Next refresh seeds cleanly to the new mode's first element. Applies to ANY state field used by a per-frame builder; the "write-once on nil" idiom is the safe pattern.

**Q96: Timestamp-interpolation with one-frame `suppressFrames` must collapse `_animFromX = _animToX` on the suppress-fire frame.**
The ZeD_ContextMenu carousel uses a triple-render scheme: `trackItems` holds 3 copies of the menu items, `pos` starts in the middle copy, and a settle timer (`animMs + 20`) silently teleports `pos` back into the middle copy whenever it strays. The teleport uses `_suppressFrames = 1` to skip animation for ONE frame — `progress = 1.0` is forced so `_currentOriginX` snaps to the new `_animToOriginX`.
**Trap:** the kick block (`if _animToOriginX ~= targetOriginX then ...`) sets `_animFromOriginX = _currentOriginX` AND `_animStartMs = getTimestampMs()` on the teleport frame. The suppress branch then forces `progress = 1.0` and yields `_currentOriginX = _animToOriginX`. But `_animFromOriginX` is still at the pre-teleport anchor, and `_animStartMs` is ~now.
**Next frame:** suppressFrames is 0 → elapsed branch fires → `elapsed ≈ 16ms`, `progress ≈ 0.08`, `p ≈ 0.22`. Interpolation: `_currentOriginX = _animFromOriginX + (_animToOriginX - _animFromOriginX) * 0.22` — pulls ~78% BACK toward the stale `from` anchor. User sees a visible backward shuffle after a LEFT-at-first-item wrap.
**Fix (S101):** when the suppress branch fires, also collapse `from = to` on all three interpolators:
```lua
if self._suppressFrames and self._suppressFrames > 0 then
    progress = 1.0
    self._suppressFrames = self._suppressFrames - 1
    justSuppressed = true
end
-- ... interpolate as usual with p ...
if justSuppressed then
    self._animFromOriginX = self._animToOriginX
    self._animFromStripW  = self._animToStripW
    -- labelX sync deferred until after its own kick block later in _layout
end
```
After this, subsequent timestamp-driven frames compute `_animTo - _animFrom == 0`, so interpolation holds at `_animToOriginX` regardless of how `progress` ramps. The next real user press triggers a new kick that sets `_animFromX = _currentOriginX` cleanly.
**General pattern:** any animation system that mixes (a) timestamp-based `elapsed / animMs` progress with (b) a one-frame "snap" escape hatch must sync `from = to` on the snap frame, or it will partially un-snap on subsequent frames. The ZeD drawer system avoids this by using delta-accumulators (`speed * dt`) instead of absolute timestamps; migration to delta-accumulators would also solve the problem but is a larger refactor.

**Q97: Gamepad context menu anchor — prefer `Focus.getFocusedElement(win)` bounds over Java-item-keyed yMap lookup.**
`Overrides/ContextMenu.lua` originally resolved gamepad inventory menu anchor by looking up `items[1]` in `win._mainContent._itemRenderYMap` (a Lua-side map keyed by Java item references, stamped each frame by `InventoryRenderer:drawItemRow`). If the lookup missed, anchor fell through to dock-bottom.
**Failure modes:** yMap was subject to timing + visibility edge cases:
- Item's category is collapsed → `drawItemRow` skipped → no stamp
- Stacking hides child items under a rep row → child stamps absent
- First-frame-after-tab-switch: renderer hasn't drawn yet → empty yMap
- Equipment-tab path invoking context menu via an inventory-row element that's technically visible but keyed differently
Result: gamepad menu silently dropped to dock-bottom instead of anchoring at the focused row.
**Fix (S101):** prefer live FocusManager state as the primary anchor source:
```lua
local focWin = Focus.getFocusedWindow()
if focWin and focWin._mainContent then
    local zone = Focus.getFocusedZone(focWin)
    if zone and (zone.zone == "charMainInv" or zone.zone == "worldMainInv") then
        local el = Focus.getFocusedElement(focWin)
        if el then
            local cnt = focWin._mainContent
            local rowH = (ZeD.T and ZeD.T.rowH) or 26
            local ax = cnt:getAbsoluteX() + math.floor(cnt:getWidth() / 2)
            local ay = cnt:getAbsoluteY() + (el.y or 0) + math.floor(rowH / 2)
            return ax, ay
        end
    end
end
-- Fallback: yMap lookup on items[1]
```
`Focus.getFocusedElement(win)` returns the live element of the currently-focused zone — authoritative for "where is the gamepad cursor right now" regardless of render timing or stacking state.
**Latent ipairs trap (fixed same session):** the fallback candidate list was `{ ZeD_CharacterWindow.getWindow() or nil, ZeD_WorldWindow.getWindow() or nil }`. When one window is closed, the list has a nil hole. `ipairs` stops at the first nil, skipping subsequent valid entries. Build the list explicitly with existence guards:
```lua
local candidates = {}
if ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow then
    local cw = ZeD_CharacterWindow.getWindow()
    if cw then candidates[#candidates + 1] = cw end
end
if ZeD_WorldWindow and ZeD_WorldWindow.getWindow then
    local ww = ZeD_WorldWindow.getWindow()
    if ww then candidates[#candidates + 1] = ww end
end
```
General rule: never rely on `ipairs({a or nil, b or nil})` — either guard each append, or iterate via `for i = 1, #t` with explicit nil checks inside.

**Q98: `string.find(s, "%s", 1, true)` does literal `%s` character search, NOT whitespace class.**
The 4th `plain=true` arg disables Lua pattern parsing — `%s` is interpreted as two literal characters (`%` followed by `s`) rather than the whitespace class. `_firstWord("Place Item")` using this pattern returned `"Place Item"` whole (no match), which meant the S103 first-word fallback in `ContextMenuRegistry.resolveIconForName` silently failed for every multi-word option label.
**Fix (S103):** use a literal space with `plain=true`:
```lua
local sp = s:find(" ", 1, true)  -- literal space, not the %s class
```
Or drop the `plain` arg to get the whitespace class (matches space, tab, newline):
```lua
local sp = s:find("%s")  -- pattern mode
```
**General rule:** when mixing `plain=true` with pattern characters (`%s`, `%w`, `%d`, `.`, `*`), the pattern semantics are lost — you get literal-character search. Either omit `plain` to use patterns, or pass plain literal characters when `plain` is set. Confirmed via live console log: `"first word: 'Place Item'"` instead of `"first word: 'Place'"`.

**Q99: `ZeD.Input.Detector.getMode()` oscillates `kbm`↔`gamepad` within consecutive frames when both input streams fire.**
Observed in S103 console logs: `mode: gamepad -> kbm` on frame 4745, then `mode: kbm -> gamepad` on frame 4770 (25 frames later), then back, repeatedly. Root cause: the detector updates mode based on discrete input events (OnKeyPressed, OnMouseDown, joypad stick deltas). If the user has a hand on the gamepad (stick drift, slight movement) AND uses mouse, BOTH event streams fire in the same input tick, racing the mode setter.
**Implication:** per-frame gating logic that reads `getMode()` is unreliable when behavior depends on mode-specific state that's STICKY across mode transitions. Example: `InventoryRenderer`'s scroll-follow guarded on `getMode() == "gamepad"` — whenever the detector flipped back to `gamepad` for a single frame, the pinned scroll snapped back even though the user was mousewheel-scrolling.
**Fix pattern (S103):** use a DELTA GATE instead of mode gate. Only mutate state when the triggering value actually CHANGED since last frame. Cache `_lastPinnedX` and only fire the pin when the current focused id differs:
```lua
if focusedItem and focusedItem ~= self._lastPinnedItem then
    -- ... pin logic ...
    self._lastPinnedItem = focusedItem
end
```
This works regardless of mode oscillation: gamepad D-pad changes focus → one pin fires → KBM user scrolls past → focus unchanged → no re-pin. Applied to `InventoryRenderer.lua:667`, `SkillsTab.lua` scroll-follow, `HealthTab.lua` scroll-follow. Supersedes the mode-gate pattern.

**Q100: Ring zone focusable builders that read late-stamped zone rects return empty on the first prerender after tab-switch.**
`Focus.setRingZoneElements(win, zoneName, elements, preserveIdx=1)` fires during `_syncRingZonesToActiveTab` on every tab-switch. The per-frame refresh in content prerender then calls `setRingZoneElements` without the preserveIdx, falling through to `_clampIdx(focusedElementIdx, elements)` which preserves the idx set by sync.
**The trap:** if a focusable builder reads a zone rect (e.g. `win._skillsGridZone`) that's stamped at the END of the tab renderer, then on the FIRST prerender after the tab-switch the rect is still nil from the prior tab → the disclosure focusable returns `{}` → the aggregator's elements array starts with the first skill row at index 1. `focusedElementIdx = 1` then points to the wrong element. The disclosure never receives initial focus.
**Fix (S103):** stamp zone rects at the TOP of the render function (as soon as x/y/w/tabHeaderH are known), not at the end. Applied to `SkillsTab.lua` (`_skillsGridZone`) and `HealthTab.lua` (`_healthFigureZone`). Frame order: sync runs → prerender (reads stamped-from-last-frame or nil on first) → tab render (stamps FRESH early → builders can read immediately next prerender).
**General rule:** any builder that reads from a renderer-stamped field must either stamp the field BEFORE the builder runs in the same frame, or accept a one-frame lag. For first-frame-after-transition correctness, stamp early.

**Q101: `drawTextureScaledAspect` tint multiplies RGB. Black-RGB-on-transparent icons render black regardless of tint.**
PZ's `panel:drawTextureScaledAspect(tex, x, y, w, h, a, r, g, b)` applies (r,g,b) as a multiplicative tint against the texture's RGB channels. For icons to recolor correctly the texture MUST be white-RGB-on-transparent-alpha — the alpha channel encodes the shape, RGB is always (255,255,255).
**The trap:** Flaticon (and many icon packs) export `fi-br-*.png` as BLACK-RGB-on-transparent-alpha by default. Tinting with `T.iconWhite = {1,1,1}` → RGB = (0,0,0) × (255,255,255) = (0,0,0) → renders black regardless. On a dark-theme paper background, icon is invisible. On light paper, still black but might be visible only if paper is light enough.
**Fix (S103):** pre-process every `fi-br-*.png` with PIL to force RGB = (255,255,255) while preserving the alpha channel:
```python
from PIL import Image
im = Image.open(path).convert('RGBA')
r, g, b, a = im.split()
white = Image.new('L', im.size, 255)
out = Image.merge('RGBA', (white, white, white, a))
out.save(path)  # idempotent — running again changes nothing
```
Then pair with an `iconTintable` flag in the registry so ZeD-mapped icons get tinted to `ink` / `textOnAccent` while vanilla item sprites (already colored) pass through with `T.iconWhite` (identity multiply). `ContextMenuRegistry.lua:201-209` sets the flag; `Molecules.lua:2702-2715` branches the tint.
**General rule:** any monochrome icon pack intended for theme-aware tinting must be white-RGB with shape in alpha. If the source is black-on-transparent, batch-process at integration time.

**Q102: Cone-nav with 2× off-axis weight + wide disclosure element + split-column layout → misroutes to interior row in opposite column.**
`FocusManager`'s spatial cone algorithm (90° cone, 2× off-axis weight, no-wrap) picks neighbors by weighted distance. For D-pad DOWN from a disclosure rect that spans the full drawer width (e.g. 500px wide), cone-nav evaluates every element below. First-row-left skill is at x-center ~100 (off-axis delta from disclosure center ~150); first-row-right skill is symmetric. BUT an interior row (e.g. 5th skill down in right column) at x-center ~350 has an x-delta of 100 and a y-delta ~180 — the WEIGHTED distance can be LOWER than the first-row targets whose 2×|off-axis| penalty dominates their low y-delta. Result: D-pad DOWN from disclosure picks the 5th skill in the right column instead of the first skill in either column.
**Fix (S103):** add explicit dispatch branches that bypass cone-nav for disclosure ↔ first-row transitions:
```lua
-- In onJoypadDirDown override:
if zone.zone == "charTabContent" then
    local el = Focus.getFocusedElement(self)
    if el and el.isDisclosure and zone.elements and zone.elements[2] then
        zone.focusedElementIdx = 2  -- first post-disclosure element
        -- fire onFocus of new element
        return
    end
end
-- In onJoypadDirUp override:
if zone.zone == "charTabContent"
   and zone.focusedElementIdx == 2
   and zone.elements[1] and zone.elements[1].isDisclosure then
    zone.focusedElementIdx = 1
    return
end
```
Applied to Skills + Health (disclosure + split-column bodies). Thermal doesn't need this — its first post-disclosure elements are centered pills, so cone-nav picks them cleanly.
**General rule:** when a focusable's width >> target-column width, cone-nav's off-axis penalty punishes the geometrically-nearest target disproportionately. Either narrow the focusable's cone-nav bounds, or use explicit directional dispatch for the transition.

**Q103: Cone-nav's 45° constraint (`|dx| > |dy| → reject`) blocks narrow-source → wide-target transitions.**
`_coneCost` in FocusManager rejects any candidate where `math.abs(dx) > math.abs(dy)` for up/down directions (and symmetric for left/right). Combined with the 2× off-axis weight, this creates a hard geometric limit: if the source element's center x differs from the target element's center x by MORE than the vertical distance, cone-nav returns silent no-op. No element picked, no focus movement.
Observed in S105: Journal sub-tab pills (narrow, top row, stacked horizontally) and their sub-tab-specific content below (wide full-drawer elements centered in x, or right-side buttons). From pill #1 (Journal, left side of strip) going DOWN to kills disclosure (full-width, x ≈ drawW/2 center), dx ≈ drawW/2 - pill1X ≈ 200, dy ≈ kills_y - pill_y ≈ 27. `|dx| > |dy|` → rejected. User presses DOWN from last pill, nothing happens.
Similar breakage on save button (right-side) → group 1 (wide) and mode pill (top-right) → first thumbnail (left-side). The cone-nav algorithm works well for grid-like layouts where adjacent elements share at least one axis, but not for narrow-to-wide pivots.
**Fix:** explicit directional dispatch branches that bypass cone-nav for known narrow→wide transitions:
```lua
-- DOWN from sub-tab pill → first sub-tab content element (idx 4, given pills at 1..3)
if zone.zone == "charTabContent" and self._activeTab == "journal" then
    local el = Focus.getFocusedElement(self)
    if el and el.subTabIdx and zone.elements and zone.elements[4] then
        zone.focusedElementIdx = 4
        -- fire onFocus
        return
    end
end
-- UP from elements[4] → pill matching currently-active sub-tab (preserves sub-tab semantics)
if zone.zone == "charTabContent" and self._activeTab == "journal"
   and zone.focusedElementIdx == 4
   and zone.elements[1] and zone.elements[1].subTabIdx then
    local target = math.max(1, math.min(3, self._journalSubTab or 1))
    zone.focusedElementIdx = target
    -- fire onFocus
    return
end
```
Use an element-shape flag (e.g. `subTabIdx` on pills) instead of index comparison so the pattern extends to other narrow→wide layouts.
**Related:** Q102 (disclosure↔first-row snap) is a special case of this — same geometry, different cause (off-axis weight instead of cone rejection). Both require explicit dispatch.
**When to apply:** Any multi-element zone where a "row" of narrow elements (pills, tabs, buttons) sits spatially adjacent to a body of wider content. Before adding the pattern: test cone-nav with print statements to confirm `dx > dy` is the failure mode; cone-nav has other failure modes too (off-axis weight, no-candidate-in-direction).
**General rule:** cone-nav assumes grid-like alignment. When layout has narrow source + wide target (or vice versa) across a pivot point, use explicit dispatch. The narrow→wide pattern appears wherever a control strip sits above/beside a content area.

**Q104: Late-declared `local X` below a closure that references X makes the reference resolve to a global (nil) instead of the late-declared local.**
Kahlua (and standard Lua) decides name-resolution scope at CLOSURE CREATION time, not at call time. When a function is defined, every free name in its body is matched against the currently-visible locals. If no local exists at that moment, the name is bound as a global lookup forever. Later `local X` declarations do NOT retroactively become the target — they create a NEW local in the enclosing chunk, separate from the global the closure already captured.
Observed in S106: `_syncRingZonesToActiveTab` was defined at line 492 and called `_buildCharacterMCColumnFocusables(win)` inside. The forward-decl `local _buildCharacterMCColumnFocusables` was placed at line 616 (below the sync function). The real assignment at line 953 assigned to that local — but the sync function's closure had already resolved the name as `_G._buildCharacterMCColumnFocusables`, which was nil. Result: tab-switch path crashed with "Object tried to call nil in _syncRingZonesToActiveTab."
**Fix (S106):** hoist forward-decls ABOVE all consumer closures, not just above the definition. Idiom for forward-decl blocks at top of file:
```lua
-- Top of file, before ANY function that might reference these:
local _buildPanelFocusables
local _buildLootFocusables
local _clearGpFocusState
local _buildCardActionFocusables
local _buildCharacterMCColumnFocusables   -- S106: must be here, not lower
local togglePinSkill
-- Now define consumers:
local function _syncRingZonesToActiveTab(win, content)
    ...
    local els = _buildCharacterMCColumnFocusables(win) or {}  -- upvalue capture
end
-- Later, assign the real function:
_buildCharacterMCColumnFocusables = function(win) ... end
```
**Diagnostic pattern:** error message "Object tried to call nil in [function_name]" where the failing function is a forward-declared local that was declared AFTER the caller's definition. Grep for `^local X` to find the declaration line; if it's below the caller's `local function`, hoist it.
**Why within-scope closures escape this:** a closure built INSIDE another function (e.g., inside `open()` or inside a panel's `_onPrerender` handler) gets its closure scope resolved when the OUTER function runs, not when the file is loaded. By the time `open()` fires, the forward-decl AND the assignment have both run, so the inner closure resolves the upvalue correctly. Only top-level functions defined during the initial file load are vulnerable.
**Related:** "common mistake #16" (generic late-local) captures the broader shape, but this closure-specific variant deserves its own Q-row because the failure mode is invisible until the offending tab-switch path fires — the rest of the file loads and runs fine.
**General rule:** treat the top-of-file forward-decl block as the declaration of every non-trivial local function that might be referenced anywhere in the file. When in doubt, hoist.

**Q105: Per-window MC toggle helpers (`mcToggleWorldContainer`, `mcToggleContainer`, `exitWorldMC`, `_syncRingZonesToActiveTab`) declared as `local function` AFTER the focusable-builder closures that reference them = silent no-op.**
Specific Q104 instance worth its own row because it bites HARD on per-window mcToggle wiring. The focusable builders (`_buildWorldLootFocusables` in World, the analog in Char) get assigned at file-load time near the top of the file; their closures' `onActivate` / `onHoldActivate` reference the mcToggle helpers. If those helpers are declared `local function` lower in the file (which is the natural reading order — toggles tend to live near the rendering code), the closures captured the names as globals at creation time. The `if mcToggleWorldContainer then ... end` guard pattern (used everywhere) silently short-circuits because the global is nil. **User-visible symptom:** holding A on a container does NOTHING. No log, no error, no MC mode entry. Same for any path that fires the helper through a closure built earlier in the file. S108 also hit this for `_syncRingZonesToActiveTab` referenced in Char's `mcToggleContainer` tail call.
**Fix (S108):** add explicit forward-decls `local mcToggleWorldContainer; local exitWorldMC; local _syncRingZonesToActiveTab` (etc.) above the EARLIEST closure that references them, then convert the `local function foo(...)` definition to `foo = function(...)` so it lands on the hoisted local instead of creating a shadowing local.
**Diagnostic:** if a `mc*Toggle*` or `_syncRingZones*` helper exists but holding A on a container does nothing (no MC mode, no log line), check that the helper is forward-decl'd above its earliest caller. Grep `^_syncRing\|^mcToggle\|^exit.*MC` and compare to first call site line numbers.
**Why this hits per-window code specifically:** focusable builders are typically grouped near the top of the file (forward-decl + assigned early so other init code can call them); MC state machine helpers tend to live mid-file near render code. Natural ordering puts builder closures BEFORE helper definitions. The `if guard then` pattern silently swallows the failure rather than crashing — which is what makes this so insidious. Easier to debug if you DROP the guard (`mcToggleWorldContainer(...)` instead of `if mcToggleWorldContainer then ...`) — then nil-call crashes loudly with the function name in the stack trace.

**Q106: Lua `not {}` evaluates to `false` — empty tables are truthy. Dirty-check patterns using `if not oldSnap then dirty = true end` only force a rebuild on the FIRST-EVER frame (when oldSnap is `nil`).**
Once oldSnap has been written (even as an empty list `{}`), subsequent frames where the snapshot REMAINS empty (item count was 0 on previous frame, still 0 this frame) skip the rebuild. The standard count-comparison dirty check `dirty = (oldN ~= newN)` returns false (0 ≠ 0 = false), so the build block doesn't fire and the focusable elements stay stale.
**Observed in S108:** `worldMainInv` per-frame refresh stayed non-focusable forever after MC entry when the floor (active container) was empty. `oldSnap = {}` from before MC entry, `newItems = {}` after MC entry, dirty stayed false, the "MC active + empty inv → emit placeholder" branch never fired. Bumper from MC zones skipped past mainInv entirely → "1 press from MC<N> to tabBar" complaint.
**Fix (S108):** add an explicit STATE-TRANSITION tracker that forces dirty when the *logical* state changes even if the *data dimensions* don't. For mainInv: `local mcActive = win._mcSelected and #win._mcSelected > 0; if win._lastMcActiveForMainInv ~= mcActive then dirty = true; win._lastMcActiveForMainInv = mcActive end`. Pattern generalizes: any per-frame dirty check that gates on data-derived quantities (count, snapshot identity) needs supplemental state-transition flags for any LOGICAL state that influences what gets built.
**Diagnostic:** if a per-frame zone refresh "stops working" after a state change but the data being read is unchanged, the dirty check is the suspect. Add a debug print of `oldN, newN, dirty` to confirm the build block is being skipped.
**Related:** Q95 (per-frame builder seed-stomp race), Q100 (zone rect early-stamp). Q106 is the third member of the "per-frame refresh patterns that fail silently" trio. All three need explicit gating that doesn't depend solely on data identity.

**Q107: FocusManager `_handleBTap` element-level `onCancel` callback has an explicit pass-through contract: `return false` = "not handled, fall through to shade-all"; any other return (nil, true, etc.) = "consumed, stop here".**
Elements that conditionally need B — e.g. dropdown that should consume B only while open — can't just "not define onCancel when closed" because the ring per-frame refresh's dirty-check only fires on first/last element id changes. If the element's id stays stable across state flips, the element table (including its onCancel field) doesn't get replaced. So the callback must be present at all times, but able to defer.
**Pattern (Foraging dropdown S109b):**
```lua
el.onCancel = function(w)
    local d = w._forageDropdown
    if not (d and d.isOpen) then return false end  -- pass through
    d.isOpen = false
    d.scrollOffset = 0
    d:setHeight(ZeD.T.inputH)
    return true  -- handled
end
```
`_handleBTap` implementation:
```lua
if el and el.onCancel then
    local ok, result = pcall(el.onCancel, w, el)
    if not ok then print("[ZeD] FocusManager onCancel failed: " .. tostring(result)) end
    if result ~= false then return end
end
_shadeAllWindows("B-tap")
```
**Why the pcall result ~= false check:** on pcall success, `result` is the callback's return. On pcall failure, `result` is the error message (a string). Strings are truthy AND not equal to the literal `false`, so `result ~= false` still returns true — we consume B on error (user doesn't get a phantom shade). Only a deliberate `return false` from the callback triggers fall-through.
**Added S109b** when forage dropdown needed conditional consume. Animals zone-draw onCancel (S109a) returns nil implicitly — which is NOT false, so treated as handled. Unchanged behavior.
**Related:** Q102 (explicit-dispatch pattern). Both are "the ring model's implicit behavior isn't quite enough; expose a callback for elements to override."

**Q108: ZeD_Dropdown is an ISPanel child whose prerender paints an opaque-ish `surf2` bg (alpha 0.92–0.95) covering its entire bounds. Gamepad focus cues painted on the PARENT panel at the dropdown's bounds get covered — only ~0.04–0.08 effective accent alpha shows through.**
The parent panel's render runs BEFORE the child panel's prerender/render in PZ's ISPanel hierarchy. Any draw on the parent at the child's bounds becomes underpaint — covered by child's opaque self-painting.
**Workaround (ForagingTab S109b):** extend the cue 3px beyond the widget bounds on all sides. The inner area gets covered by the widget's bg, but the 3px halo strip around the widget remains visible.
```lua
if _gpFocusMatches(win, function(el) return el.isDropdown end) then
    local cx = x + FOCUS_PAD_X
    local cy = y + math.floor((h - T.inputH) / 2)
    local pad = 3
    _paintGpCue(panel, cx - pad, cy - pad, ddW + pad * 2, T.inputH + pad * 2)
end
```
**Alternative approaches (rejected):** (a) Hook ZeD_Dropdown's own prerender/render to paint cue after its bg — invasive, modifies widget class. (b) Paint cue AFTER ZeD_Dropdown.render by reordering — not possible from parent render context.
**When dropdown opens**, its height expands (inputH → inputH + rowH × maxVis). The halo is still visible on 3 sides (top/left/right) of the top `inputH × dd.width` portion; the expanded list area below paints its own bg but user is inside the dropdown widget anyway so the halo isn't needed mid-option.
**Generalizes to:** any ISPanel widget that self-paints an opaque bg. Text entries (`ISTextEntryBox`), scroll bars, other child widgets — all require the halo workaround for parent-painted cues. Alternative: paint cue WITHOUT extending bounds AFTER the widget renders, but that requires reaching into the widget's render pipeline.


**Q109: B42.17.0 removed `isJoypadPressed(id, buttonConst)` from engine-exposed Lua globals. All per-tick joypad button polling must migrate to `JoypadButton.<n>:isDown(id)`. Integer dispatch constants (`Joypad.AButton`, `Joypad.LBumper`) unchanged — only the polling calls are affected. Related shortcut helpers also removed: `isJoypadRBPressed`, `isJoypadLBPressed`, `isJoypadAPressed`, `getJoypadXButton`, `getJoypadAButton`, and all `getJoypad<Letter>Button(id)` variants.**

Patch shipped 2026-04-20. Vanilla PZ Lua no longer contains a single reference to `isJoypadPressed` — the migration is complete on Indie Stone's side. Runtime symptom if unmigrated: `"Object tried to call nil in pcall"` fires every tick on the offending OnTick handler. pcall keeps the game from crashing but spams console.txt at the tick rate.

**Two-namespace gotcha:** Two distinct namespaces coexist and are NOT interchangeable.
- `Joypad.XButton` / `Joypad.LBumper` / `Joypad.DPadUp` — **integer constants**, still arrive as the `button` argument in `onJoypadDown(button)` dispatch callbacks. NOT removed. Keep `if button == Joypad.XButton then` lines as-is.
- `JoypadButton.X` / `JoypadButton.LeftBump` / `JoypadButton.DPadUp` — **Java objects** with `:isDown(controllerId)` method. NEW polling path. Use in OnTick, timer callbacks, anywhere you need "is this button currently held?"

Colon syntax is mandatory — `JoypadButton.A.isDown(id)` (dot) does not work; must be `JoypadButton.A:isDown(id)`.

**Name-drift traps (these bite hardest):** Four buttons have renames between the dispatch-constant form and the poll-object form:

| Dispatch constant (unchanged) | Poll object (NEW, B42.17+) |
|---|---|
| `Joypad.LBumper` | `JoypadButton.LeftBump` |
| `Joypad.RBumper` | `JoypadButton.RightBump` |
| `Joypad.LStickButton` | `JoypadButton.LeftStick` |
| `Joypad.RStickButton` | `JoypadButton.RightStick` |

`JoypadButton.LBumper` does not exist and silently no-ops with a nil-index error. Most other buttons transfer by dropping "Button" (`Joypad.AButton` → `JoypadButton.A`). DPad names transfer cleanly (`Joypad.DPadUp` → `JoypadButton.DPadUp`). NEW addition: `JoypadButton.Guide` (home/PS/Xbox button) has no old equivalent.

**Full translation table for polling calls:**
```
isJoypadPressed(id, Joypad.AButton)      → JoypadButton.A:isDown(id)
isJoypadPressed(id, Joypad.BButton)      → JoypadButton.B:isDown(id)
isJoypadPressed(id, Joypad.XButton)      → JoypadButton.X:isDown(id)
isJoypadPressed(id, Joypad.YButton)      → JoypadButton.Y:isDown(id)
isJoypadPressed(id, Joypad.LBumper)      → JoypadButton.LeftBump:isDown(id)     *** rename ***
isJoypadPressed(id, Joypad.RBumper)      → JoypadButton.RightBump:isDown(id)    *** rename ***
isJoypadPressed(id, Joypad.LStickButton) → JoypadButton.LeftStick:isDown(id)    *** rename ***
isJoypadPressed(id, Joypad.RStickButton) → JoypadButton.RightStick:isDown(id)   *** rename ***
isJoypadPressed(id, Joypad.DPadUp)       → JoypadButton.DPadUp:isDown(id)
isJoypadPressed(id, Joypad.DPadDown)     → JoypadButton.DPadDown:isDown(id)
isJoypadPressed(id, Joypad.DPadLeft)     → JoypadButton.DPadLeft:isDown(id)
isJoypadPressed(id, Joypad.DPadRight)    → JoypadButton.DPadRight:isDown(id)
isJoypadPressed(id, Joypad.Back)         → JoypadButton.Back:isDown(id)
isJoypadPressed(id, Joypad.Start)        → JoypadButton.Start:isDown(id)
```

**Axes migrated in parallel** (same shape: object with `:getValue(controllerId)` / `:getDeadZone(id)` / `:setDeadZone(id, v)`):
```
JoypadAxis1d.LeftStickX
JoypadAxis1d.LeftStickY
JoypadAxis1d.RightStickX
JoypadAxis1d.RightStickY
JoypadAxis1d.LeftTrigger
JoypadAxis1d.RightTrigger
JoypadAxis1d.getAxisCount()
JoypadAxis1d.fromIndex(n)    -- 0-indexed
```
Numeric-index `getControllerAxisValue(ctlIdx, axisIdx)` still works fine — used by InputModeDetector and FocusManager aiming-escape polling. The `JoypadAxis1d.<n>:getValue(id)` form is the new named-API alternative.

**Enumeration helpers (new):**
```lua
local n = JoypadButton.getButtonCount()    -- ~40 buttons max
for i = 1, n do
    local btn = JoypadButton.fromIndex(i - 1)    -- 0-indexed
    if btn:isDown(controllerId) then ... end
end
```

**Texture tables unchanged** — keyed by the new objects (`Joypad.ButtonTextures[JoypadButton.A]`, `Joypad.AxisTextures[JoypadAxis1d.LeftTrigger]`).

**JoypadState unchanged** — `JoypadState.players[i+1]` still the canonical player-joypad struct; `.id` field still the controller integer; `setJoypadFocus` / `getFocusForPlayer` / `getJoypadData` all preserved.

**ZeD-specific call-site inventory (S110 target, 8 sites across 2 files):**

- `BumperChord.lua:188` — `isJoypadPressed(joypadIdx, Joypad.LBumper)` → `JoypadButton.LeftBump:isDown(joypadIdx)`
- `BumperChord.lua:189` — `isJoypadPressed(joypadIdx, Joypad.RBumper)` → `JoypadButton.RightBump:isDown(joypadIdx)`
- `FocusManager.lua` `_currentDpadDir` (four lines) — `Joypad.DPadUp/Down/Left/Right` → `JoypadButton.DPadUp/Down/Left/Right:isDown(jid)`
- `FocusManager.lua` `_onTick` §B — `isJoypadPressed(jid, Joypad.YButton)` → `JoypadButton.Y:isDown(jid)`
- `FocusManager.lua` `_onTick` §C — `isJoypadPressed(jid, btnInt)` where `btnInt = (_holdButton == "Y") and Joypad.YButton or Joypad.BButton`. Reshape to `local btnObj = (_holdButton == "Y") and JoypadButton.Y or JoypadButton.B` then `btnObj:isDown(jid)`.
- `FocusManager.lua` `_onTick` §C2 — `isJoypadPressed(jid, Joypad.AButton)` → `JoypadButton.A:isDown(jid)`

Third-party `PS5 DualSense Support/JoyPadMovementFix.lua:133` hits the same engine removal and confirms the issue is engine-wide, not ZeD-specific.

**Diagnostic grep for any mod:**
```
grep -rn "isJoypadPressed\|isJoypadRBPressed\|isJoypadLBPressed\|isJoypadAPressed\|getJoypad[XABY]Button" path/to/mod/
```

Any hits = broken on B42.17. Vanilla patch compaction of Crafting/Building windows (reduced widths, rearranged control boxes, compacted input/output panels) is UI-layout-only and does not affect mods that consume the data-layer APIs (`HandcraftLogic`, `BuildLogic`, `CraftRecipe` getters, event listeners). ZeD's CraftingCore is data-layer, so no regression expected there from the vanilla UI changes.

---

**CUSTODIAN NOTE:** This file is a Q109 append-ready block. Next session's session-docs custodian should concatenate this to the end of `PZAPI-KNOWLEDGE-BANK.md` (after Q108), then delete this file. Kept as a standalone to avoid risk of a silent large-file-write truncation corrupting the main KB. Session S110 can either:
1. Custodian: `Get-Content PZAPI-KB-Q109-APPEND.md | Add-Content PZAPI-KNOWLEDGE-BANK.md`, then remove the append file.
2. Manual paste: open both files, paste Q109 block at end of PZAPI-KB, save, delete append file.

---


**Q110: PZ fires onJoypadDown(button) AND onJoypadDir* for the same physical D-pad press. Handle only ONE path per direction or users see double-step navigation.**

When a D-pad direction is pressed, PZ's joypad dispatcher delivers TWO callbacks to the focused UI element on the same tick:
1. `onJoypadDown(button)` with `button == Joypad.DPadLeft/Right/Up/Down` (generic button callback)
2. `onJoypadDirLeft/Right/Up/Down(joypadData)` (named directional callback)

Both are delivered regardless of what the element implements. If the element responds to both, any action triggered (cursor advance, list scroll, cell selection) fires twice per physical press.

**Symptom pattern:** gamepad D-pad navigation jumps two cells per press; some items become unreachable because the double-step skips over them; pressing D-pad rapidly feels like page-jumping instead of row-stepping.

**ZeD convention locked in S111:**
- `onJoypadDown(button)` handles **discrete buttons** only: A, B, X, Y, LB, RB, Back, Start.
- `onJoypadDirLeft/Right/Up/Down` handles **directional nav** exclusively.

Do NOT branch on `Joypad.DPadLeft/Right/Up/Down` inside `onJoypadDown`. Leave them to the named direction callbacks. Engine delivers both regardless, so omitting the branches in `onJoypadDown` is safe — nothing gets lost.

**Audit grep for offenders:**
```
grep -rn "Joypad.DPad[LRUD]" <mod>/42/media/lua/ | grep -v "^-- "
```
For any class that also implements `onJoypadDir*`, delete those D-pad branches from `onJoypadDown`.

**S111 hit:** `ZeD_ContextMenu:onJoypadDown` had branches for `Joypad.DPadLeft`/`DPadRight` calling `self:prev()`/`self:next()` AND also implemented `onJoypadDirLeft`/`onJoypadDirRight` that called the same functions. Every D-pad press advanced 2 cells. Fix: removed D-pad branches from `onJoypadDown`.

---

**Q111: Kahlua silently disables a mod Lua file that has any parse error. No globals set, no top-level code runs, but the file "loads successfully" from `require`'s point of view. Diagnostic instrumentation added to the broken file is ALSO a no-op.**

When PZ's Kahlua compiler hits a syntax error in a mod `.lua` file, the file is flagged as failed and none of its top-level code executes. BUT:
- `require "X/Y"` does not propagate the error to the caller — it returns as if the require succeeded
- Subsequent callers see the module's namespace as empty (never populated)
- Any `_G.X = Y` sentinels, `print()` statements, or other instrumentation you add TO the broken file are all no-ops (the file never executes a single line)
- Other mod files that happen to also reference symbols the broken file should set see nil

**Symptom pattern that demands this check first:**
- Globals a mod file should set are nil after restart
- A table the mod declares (`ZeD.ContextIcons = {...}`) is empty or nil
- A `require` call appears to succeed but the required module's top-level code clearly never executed
- `print()` output from the file never reaches console.txt even though other modules' prints do
- Diagnostic instrumentation added to the file also produces no output

All symptoms mean the file failed to parse. The signal is in the debug logs — PZ reports parse errors but NOT as `ERROR` or `Exception`. Typical phrases to grep:
- `error loading`
- `error in file`
- `unexpected symbol`
- `syntax error`
- `'<eof>' expected`
- `malformed number`
- `LuaManager`
- `chunkname`

PZ ALSO shows these on the main-menu dialog at launch, but both channels have the same information.

**Common parse-error causes:**
- Stray characters from bulk-edit tooling (e.g., a literal `n` left behind from mangled `\r\n` escapes in shell commands)
- UTF-8 mojibake (`â€"` or similar sequences from double-encoding) — even inside comments, Kahlua's lexer can choke if the multi-byte sequence contains a byte the lexer parses as a token boundary (like a literal `"`)
- Unbalanced braces, brackets, or quotes after regex-based text manipulation on large files
- Lua 5.3+ syntax (goto labels, bitwise operators, integer literals) that Kahlua 5.1-based compiler rejects
- Very large single-table literals — though Kahlua's published limits are high, double-check if pushing past 1000 entries

**Diagnostic rule (lesson from S111):** when mod code silently doesn't work after an edit, grep the shared debug logs for the parse-error phrase set BEFORE writing any instrumentation. The instrumentation you'd add lives in the same file that's failing to parse, so it won't fire. Go up one level and look at how PZ reports the failure.

**S111 post-mortem:** a stray `n` character at line 396 of ContextIcons.lua (from an earlier bash-escape mishap when appending a block) broke parse of the entire 988-entry table. `ZeD.ContextIcons` stayed nil, all icon resolves returned nil, every context menu option rendered as letter fallback. Spent ~2 hours writing progressively more elaborate diagnostic sentinels (print, module-load markers, 4 global sentinel locations in ContextMenuRegistry AND ContextIcons) — every sentinel added to the broken file produced no output because the broken file never executed. Eventually reached the question via an unrelated global in ContextMenuRegistry that confirmed `ZeD.ContextIcons` was empty at require time, pointing to ContextIcons itself as the failure. A grep for `error loading` / `syntax error` / `LuaManager` in the user's first-round debug log would have pointed at line 396 directly — 15-second diagnosis vs 2 hours of layered instrumentation.

---

**Q112: `Events.OnPostUIDraw` does NOT exist as a vanilla PZ Lua event. `LuaEventManager.AddEvent("OnPostUIDraw")` followed by `Events.OnPostUIDraw.Add(fn)` silently materializes a never-firing event slot — file load succeeds, AddEvent succeeds, .Add succeeds, but the registered callback is never invoked.**

Verified by grepping vanilla PZ Lua source: `OnPostUIDraw` / `OnPreUIDraw` appear in zero vanilla files. Only `OnRenderTick` is used for post-draw work (`shared/JoyPad/JoyPadSetup.lua:1218`). Mods using `OnPostUIDraw` will load cleanly but never fire — the silent failure mode is the trap.

**Fix:** for ZeD-UI debug overlays + post-draw work that needs a valid panel context, **monkey-patch `ZeD_Window:render`** at `OnGameStart`:

```lua
Events.OnGameStart.Add(function()
    if ZeD_Window and ZeD_Window.render then
        local _origRender = ZeD_Window.render
        function ZeD_Window:render()
            _origRender(self)
            if myDebugFlag and myFocusedWindow == self then
                pcall(myDrawOverlay)
            end
        end
    end
end)
```

The patched render runs AFTER the original — the panel's draw context is still active so `self:drawRect/drawText` work. Wrap in `pcall` so overlay bugs never take down the game. Discovered S113c when F9 debug overlay didn't paint despite F9 toggle firing correctly; root cause was the bogus event subscription.

**Where to use OnRenderTick instead:** if you need post-draw work that's NOT scoped to a specific panel (e.g., fullscreen HUD overlay, screen-wide effect), `OnRenderTick` is the closest vanilla equivalent.

---

**Q113: `Keyboard.KEY_F11` is bound by vanilla to "Toggle Lua Debugger" (`shared/keyBinding.lua:353`). Pressing F11 in debug mode opens the engine's Lua debugger window. Custom mod debug toggles MUST avoid F11.**

Tested unbound function keys for ZeD-UI mod-side debug toggles:
- `KEY_F8` — reserved by `WorldMapEditor.lua:209` (only fires when in map editor; safe outside it but conflicts if user has editor open).
- `KEY_F9` — **safe.** Verified unbound in `shared/keyBinding.lua` and across `media/lua/`.
- `KEY_F10` — bound to other vanilla actions (`shared/keyBinding.lua:187`).
- `KEY_F11` — Toggle Lua Debugger (DO NOT USE).
- `KEY_F12` — typically Steam screenshot binding (engine-side, not vanilla Lua).

**Recommendation:** `KEY_F9` is the safest function-key slot for mod-side debug toggles. For ZeD-UI specifically, F9 is now claimed by FocusManager's cone-nav debug overlay.

**Symptom of accidental F11 use:** user presses your debug toggle, the Lua debugger window pops up over the game, gameplay/UI stops responding, presents as "the mod crashed" even though no Lua error occurred. Discovered S113c.

---

**Q114: `ZeD.Molecules.drawActionStrip` (and `drawVerbStrip`) returns rects in ABSOLUTE screen coordinates, not panel-local.**

From `Molecules.lua:1687`:
```lua
rects[i] = {x = absX + bx, y = absY + y, w = btnSz, h = btnSz}
```
where `absX = panel:getAbsoluteX()` and `bx` is the panel-local offset. The rects are pre-offset for screen-space hit testing in mouse handlers.

**Trap:** if you feed these rects directly into a flat-focusables system that ALSO translates panel-local → window-local at dispatch (e.g., FocusManager's `_collectFlat`), you get a DOUBLE offset — the focusable's bounds end up outside the window's bbox by the panel's absolute offset. Cone-nav can't reach them; visual paints land in the wrong spot; B-press onCancel never fires because focus never actually lands on the button.

**Fix:** before returning the rects to the focusable system, convert ABSOLUTE → panel-local by subtracting the host panel's absolute coords:

```lua
local drawerPanel = win._itemDrawerPanel
local panelAbsX = drawerPanel:getAbsoluteX()
local panelAbsY = drawerPanel:getAbsoluteY()
for i = 1, #els do
    local el = els[i]
    el.x = el.x - panelAbsX
    el.y = el.y - panelAbsY
    -- ...wrap callbacks...
end
```

Then `_collectFlat`'s panel-offset translation lands the bounds in window-local correctly. Applied in `_buildCardActionFocusables` (CW) + `_wireWorldCardButtonNav` (WW) at S113c.

**Symptom:** card buttons appear visually correct (the card organism paints them at absolute coords directly), but cone-nav from inv to card lands "wrong" — buttons appear in inverted D-pad sequence, can't reach them reliably, B-press to close drawer doesn't work because focus isn't on a card button when user thinks it is.

---

**Q115: Cone-nav across multiple panels requires CONSISTENT coordinate space. Each ZeD-UI ring zone's elements may be stored in DIFFERENT panel-local coord spaces (skill rows panel-local to drawer, invrows panel-local to content panel, container buttons panel-local to container strip — all stamping `x=0` for their respective panel left edges).**

The cone-nav math (`_coneCost`, `_halfPlaneCost`) treats all element coords as if they share one space. Without translation, two zones with `x=0` in different panels collide and cross-zone L/R rejects valid candidates as `dx == 0`.

**Symptom:** D-pad RIGHT from a skill row goes to a container button (correctly to the right) BUT skips the inventory rows in between; D-pad LEFT from a container button goes to a body part on the equipment figure (far left) instead of inventory rows in the middle. Initially confusing because cone-nav DOES work intra-zone (all elements in same panel = consistent space).

**Fix:** at FocusManager `_collectFlat` time, translate each element's bounds to a common space (window-local) by adding the source panel's `getX()/getY()`. Requires a zone-name → window-field-name map so the FocusManager can look up which panel each zone belongs to:

```lua
local _zonePanelField = {
    charTabBar         = "_tabStripPanel",
    charTabContent     = "_drawerPanel",
    charMainInv        = "_contentPanel",
    charItemCard       = "_itemDrawerPanel",
    charContainerStrip = "_containerStrip",
    -- charMC<N> via prefix match → "_contentPanel"
    -- World mirrored: worldTabBar = "_actionTabStrip", etc.
}
```

Each window must EXPOSE its panels as `win._<fieldName>` for the lookup to resolve. Char and World windows already exposed `_contentPanel`, `_drawerPanel`, `_itemDrawerPanel`, `_containerStrip`. Tab strip needed an explicit assignment in S113c (CW had only a local `strip` variable; added `win._tabStripPanel = strip`). World already had `win._actionTabStrip`.

**Generalization rule:** any new ZeD ring zone that lives on a NEW panel must:
1. Expose the panel as `win._<panelName>`.
2. Register the zone-name → field-name mapping in `_zonePanelField` (FocusManager.lua, S113c block).

Without both, cone-nav into/out of that zone will silently misroute via collapsed coord space. The symptom is direction-and-zone dependent — each new zone needs its own discovery cycle without this rule baked in.

**Translation lives in `_collectFlat`** — translates a SHALLOW COPY of each element's `x/y` (preserves callbacks/ids by reference). Original elements in `w._focusRing[zoneIdx].elements` are unchanged so existing render code that uses them with their native panel context (e.g., per-zone hover hit-testing in renderers) is unaffected.

---

**Q116: `getDeviceData():getPower()` returns a 0..1 FLOAT, not a 0..100 percentage.**

Vanilla `RWMPower:powerUpdateSimulation` (`RadioCom/RadioWindowModules/RWMPower.lua:113-122`) is the proof — line 117 does `pwr = pwr - 0.01`, line 118 does `if pwr < 0 then pwr = 0`. So the engine treats `getPower()` as a 0..1 normalized charge level, NOT a percentage.

```lua
-- WRONG (S115a first cut): bar segments compute battery/100, gives ~0.01 → floor 0 → 0 segments always
local battK = math.floor((battery / 100.0) * 4 + 0.5)

-- RIGHT: battery is already in 0..1 scale
local battK = math.floor(battery * 4 + 0.5)
```

**Default fallback** when `getPower` is missing on a derived class should be `0` (empty), NOT `100` — a safer default that doesn't paint a "full" battery for a missing device.

Also gate UI on `getHasBattery()` — a battery-powered radio with no battery installed should read empty regardless of whatever stale `getPower()` returns. Use `getIsBatteryPowered()` to check the device wants a battery at all (some external/wired devices don't).

**Effective-power gate (anti-exploit pattern):** combine user-on with usable-power so a dead/missing battery doesn't let the player passively read live frequency / station name / signal strength while the radio is "off":

```lua
local userOn     = dd:getIsTurnedOn()
local batPowered = dd:getIsBatteryPowered()
local hasBat     = dd:getHasBattery()
local charge     = dd:getPower() or 0
local extPower   = dd:canBePoweredHere()
local hasUsablePower = batPowered and (hasBat and charge > 0) or extPower
local effectiveOn    = userOn and hasUsablePower
```

Mirrors vanilla `ISRadioAction:isReallyRunning` (`RadioCom/ISRadioAction.lua:39`).

---

**Q117: PZ stores radio channel as `MHz × 1000`, not as Hz or kHz.**

Vanilla `RWMGeneral:setInfoLines` (`RadioCom/RadioWindowModules/RWMGeneral.lua:80`) is the canonical reference:

```lua
self:addInfoLine(getText("IGUI_RadioFrequency")..":   ", tostring(self.deviceData:getChannel()/1000).." MHz");
```

So a value of 88000 displays as `88 MHz`, 96500 as `96.5 MHz`. The unit is fixed regardless of band. PZ has no AM/long-wave band in lore — radios are FM-only by default.

**To display:** divide raw channel by 1000 and label as MHz. For 0.1 MHz step granularity (standard FM tuning grid), increment/decrement raw channel by `100`:

```lua
local function _splitFrequency(hz)
    if hz == nil or hz == 0 then return "---.-", "MHz" end
    return string.format("%.1f", hz / 1000), "MHz"
end

-- Step 100 raw = 0.1 MHz visible → all PZ stations tunable
local SEEK_STEP = 100
```

**Initial S115 first-cut bug:** displayed channel as kHz with `string.format("%.1f kHz", hz / 1000)` — same numerical math, wrong unit label. The user thought they were tuning across kHz when stations actually live in the MHz space the engine reports. Stations "felt unreachable" until the unit was corrected.

---

**Q118: `zomboidRadio` is NOT a global — must call `getZomboidRadio()` to fetch the singleton.**

Vanilla `RWMGeneral.lua:69-77` is the reference pattern:

```lua
local zomboidRadio = getZomboidRadio();
if zomboidRadio then
    local channelName = zomboidRadio:getChannelName(self.deviceData:getChannel())
                        or getText("IGUI_RadioUknownChannel");
end
```

Bare reference `zomboidRadio` resolves to nil. Calls like `zomboidRadio:getChannelName(channel)` then silently no-op (if/then guards) or crash (without guards). S115 first-cut wired the channel-name lookup with the bare global — station resolution was completely broken until Q118 was discovered through user testing ("can't find any stations").

**Pattern:**

```lua
local zr = (getZomboidRadio ~= nil) and getZomboidRadio() or nil
if zr ~= nil and zr.getChannelName ~= nil and channel > 0 then
    local resolved = zr:getChannelName(channel)
    if type(resolved) == "string" and resolved ~= "" then
        -- station found, use resolved name
    end
end
```

**`getChannelName(freq)` returns nil when no station is currently airing on that frequency** — most PZ stations have airtime schedules and go silent overnight. Even with the call wired correctly, names won't resolve at 2-3am in-game; verify daytime first when testing.

---

**Q119: Kahlua's `pcall` STILL logs the inner error to console as a stack trace even when the error is caught.**

Defensive `pcall(function() return obj:getThing() end)` patterns trigger one stack-trace dump in `console.txt` per error per render frame, even though the surrounding code happily proceeds with the false-return. PZ's Kahlua integrates with the engine's error logger, so any `KahluaUtil.fail` from inside the protected block fires the engine's debug log path.

**Symptom:** console.txt grows with hundreds-to-thousands of repeated `Tried to call nil` stack traces every render frame, despite the surrounding code handling the failure cleanly. Game runs fine but logs become unreadable and disk usage balloons.

**Fix — field-probe pattern (no pcall):** check the method's existence via `obj.method ~= nil` BEFORE calling. Kahlua's table indexing returns nil silently for missing keys (no stack trace), so the field check is free:

```lua
-- WRONG: defensive pcall, still logs stack trace per failure
local ok, v = pcall(function() return dd:getDeviceVolume() end)
if ok and v ~= nil then ... end

-- RIGHT: field probe, silent on missing methods
if dd.getDeviceVolume ~= nil then
    local v = dd:getDeviceVolume()
    if v ~= nil then ... end
end
```

The pattern compounds for chained access — check each step:

```lua
if dd.getDevicePresets ~= nil then
    local pc = dd:getDevicePresets()
    if pc ~= nil and pc.getMaxPresets ~= nil then
        local mx = pc:getMaxPresets()
    end
end
```

**Use pcall ONLY when** the method exists but might throw a Java RuntimeException through the bridge (e.g., `IndexOutOfBoundsException` from `ArrayList:get(N)` — see Q120). For "is this method exposed?" checks, field probe.

**Helper used in `RadioTab.lua`:**

```lua
local function _safeGet(dd, fnName, fallback)
    if dd == nil then return fallback end
    local fn = dd[fnName]
    if fn == nil then return fallback end
    local v = fn(dd)
    if v == nil then return fallback end
    return v
end
```

Uses field-table indexing (`dd[fnName]`) to look up without invoking — silent on miss.

---

**Q120: Java `ArrayList:get(N)` for `N >= size()` throws `IndexOutOfBoundsException` through the Kahlua bridge as a per-frame stack trace.**

Even with defensive `pcall` (Q119), the trace logs. Even with the `pc.getPresets ~= nil` field-probe guard, calling `get(i-1)` when `i > size()` still throws.

**Symptom:** preset bank with fewer-than-N stored entries logs IndexOutOfBoundsException every render frame for each empty slot.

**Fix:** read `:size()` once, only iterate `:get()` up to that bound:

```lua
local listSize = 0
if presetList.size ~= nil then
    listSize = presetList:size() or 0
end

for i = 1, visible do
    if presetList.get ~= nil and i <= listSize then
        local entry = presetList:get(i - 1)
    end
end
```

**General rule:** treat `:size()` like a precondition check — read it before any indexed access and bound the loop accordingly. Same applies to `getXxxList():get(N)` patterns across vanilla.

---

**Q121: `local function name(...)` after `local name` forward-decl creates a NEW shadowing local, NOT an assignment to the forward-decl.**

Lua's `local function` is sugar for `local name = function() end` — but with the gotcha that it RE-DECLARES the local in the current scope. If a forward-decl `local name` already exists higher up, `local function name(...)` shadows it, leaving the upvalue captured by earlier closures pointing at nil forever.

```lua
-- BUG: render() captures _channelStep as upvalue at definition time.
-- The local function below creates a SHADOWED local, the upvalue stays nil.
local _channelStep
function ZeD.RadioTab.render(...)
    if win._radioSeekHold then
        _channelStep(dd, dir)  -- FIRES nil call — closure captured the FIRST local
    end
end
local function _channelStep(dd, dir) end  -- WRONG, shadows the forward decl

-- FIX: assign to the existing forward-decl local via plain `name = function`
local _channelStep
function ZeD.RadioTab.render(...) end
_channelStep = function(dd, dir) end  -- RIGHT, binds to forward-decl
```

**Symptom:** function-call site logs `Tried to call nil` despite the function being "defined" later in the file. Particularly insidious because the function APPEARS visible at the call site (same scope, declared higher up) — but the closure bound to the earlier nil version, not the post-declaration redefinition.

**General rule:** forward-decl + later definition pair MUST use `name = function(...)` syntax for the definition. NEVER mix `local name` (forward-decl) with `local function name(...)` (definition).

---

**Q122: Mutate-in-place token table pattern preserves table identity across `/lua reload`, so applyTheme() doesn't need to re-fire to propagate token changes.**

**Problem:** Tokens.lua defines `ZeD.Radio = { pt = {...}, vt = {...} }` (table literal). On reload, this REPLACES the table — assigns a NEW table to `ZeD.Radio`. Any captured reference (e.g., `T.radio = ZeD.Radio` set inside applyTheme) still points at the OLD table with the OLD field values. Edits to Tokens.lua appear to "not take effect" until applyTheme re-fires (theme switch, restart).

**Fix:** declare the table once, then mutate fields per-line. Identity is preserved across reload because `ZeD.Radio = ZeD.Radio or {}` keeps the existing table when present, and per-field assignment writes new values into the SAME table.

```lua
-- WRONG: replaces table identity on reload
ZeD.Radio = {
    pt = { btnBg = hex("#C8C8C8") },
    vt = { btnBg = hex("#2A2A2A") },
}

-- RIGHT: mutate-in-place; T.radio still resolves to the live table
ZeD.Radio = ZeD.Radio or {}
ZeD.Radio.pt = ZeD.Radio.pt or {}
ZeD.Radio.vt = ZeD.Radio.vt or {}
ZeD.Radio.pt.btnBg = hex("#C8C8C8")
ZeD.Radio.vt.btnBg = hex("#2A2A2A")
```

Now `/lua reload` rewrites the leaf hex values into the existing tables. Code that captured `T.radio = ZeD.Radio` (inside applyTheme) still has the right reference; the values it reads are the new ones.

**Use this pattern for all top-level token namespaces** that get assigned to `T.<x>` once at applyTheme time — `ZeD.Spacing`, `ZeD.Ctx`, `ZeD.Gp`, `ZeD.Radio`, future namespaces. Theme-dependent palettes still need full applyTheme rebuild per theme switch, but per-field hex tweaks no longer require it.

---

**Q123: PZ Fira font set lacks Unicode bullet glyphs `●` (U+25CF) / `○` (U+25CB) — they render as `?` placeholders.**

The Fira Mono / Fira Sans bundle this mod ships covers ASCII + extended Latin but not the bullet glyph block. Any string containing `●` / `○` shows `?` at those code points.

**Fix — paint indicator squares via `drawRect` instead of glyph rendering:**

```lua
local fh   = TM:getFontHeight(font)
local sqSz = math.max(6, math.floor(fh * 0.55))
local sqY  = y + math.floor((fh - sqSz) / 2)
if on then
    panel:drawRect(x, sqY, sqSz, sqSz, c.a, c.r, c.g, c.b)
else
    panel:drawRectBorder(x, sqY, sqSz, sqSz, c.a, c.r, c.g, c.b)
end
panel:drawText(text, x + sqSz + 4, y, c.r, c.g, c.b, 1, font)
```

Encapsulated in `Molecules.drawStatusChip(panel, x, y, text, on, onColor, offColor, font)` (S115). Returns the total width drawn so callers can lay out chip rows left-to-right.

**Other Unicode glyphs to check before using:** `▶ ◀ ▲ ▼ ★ ↑ → ✕ ✓ … °`. Some render, some don't. Prefer ASCII (`< > |` etc.) when possible. The arrow texture system in `AtomExtensions._getArrowTex` is the canonical workaround for triangles.

---

**Q124: Vanilla auto-opens `ISRadioWindow` on `OnEquipPrimary` / `OnEquipSecondary` — must `Events.X.Remove` the handler at OnGameBoot to suppress.**

`RadioCom/ISRadioWindow.lua:412-413`:

```lua
Events.OnEquipPrimary.Add(ISRadioWindow.onEquip);
Events.OnEquipSecondary.Add(ISRadioWindow.onEquip);
```

This makes equipping any radio item pop the legacy `ISRadioWindow` floating UI — covers ZeD chrome, steals focus. For mods replacing the radio surface (like ZeD's RadioTab), the suppression must remove the handler explicitly.

**Pattern:**

```lua
-- Overrides/RadioWindow.lua — auto-loaded by PZ since under media/lua/client/
local function suppressVanillaRadioAutoOpen()
    if ISRadioWindow == nil or ISRadioWindow.onEquip == nil then return end
    if Events and Events.OnEquipPrimary and Events.OnEquipPrimary.Remove then
        Events.OnEquipPrimary.Remove(ISRadioWindow.onEquip)
    end
    if Events and Events.OnEquipSecondary and Events.OnEquipSecondary.Remove then
        Events.OnEquipSecondary.Remove(ISRadioWindow.onEquip)
    end
end

-- Defer to OnGameBoot so vanilla's top-level Add() calls have already fired.
Events.OnGameBoot.Add(suppressVanillaRadioAutoOpen)
```

**Right-click "Use" path** on world radios still calls `ISRadioWindow.activate(...)` directly via `ISWorldObjectContextMenu.lua:222` — that's user-initiated and rare; suppress when the ZeD context-menu route is wired (deferred from S115).



---

**Q129: `getText(key)` on a format-string key with no arguments logs a Java `MissingFormatArgumentException` WARN (`Translator.reportMissingArgumentsFromPastAbuse`).**

Found S123 (Oct 12 2026) on stable 42.20.2. Keys such as `Fluid_HoldingNone`, `Fluid_HoldingOneType`, `Fluid_HoldingTwoTypes` contain `%1$s` / `%2$s`. `ContextMenuRegistry.buildTranslatedCache` resolves every icon-map key generically, so the first context-menu open logged six WARN lines. `pcall` does not help: PZ catches the Java exception itself and returns a string, then logs.

**Pattern:** pad generic lookups with blank args — `getText(key, "", "", "")`. Java's `String.format` ignores surplus arguments, so keys without specifiers are unaffected.

---

**Q130: `loadstring` exists in PZ's Kahlua, and `getFileReader` / `getFileWriter` resolve relative to `Zomboid/Lua/`. With `-debug` this is a no-restart test bridge.**

Found S123. The debug Command Console's "Lua Command Line" runs arbitrary chunks. Defining once per game session:

```lua
function zq() local r=getFileReader('zedqa.lua',false) local s='' local l=r:readLine() while l do s=s..l..string.char(10) l=r:readLine() end r:close() print('zedqa',pcall(loadstring(s))) end
```

then every test is: write `Zomboid/Lua/zedqa.lua` from outside the game, type `zq()`, read `print` output in `console.txt`. `readLine()` returns nil at EOF. Chunks can arm an `Events.OnTick` counter to sequence timed-action checks. Used in S123 to verify every ItemCard header verb and walk all 13 tabs with zero manual clicks. Also compiles mod files for syntax without executing them (`loadstring(src, name)` returns nil + message on a parse error).

---

**Q131: Stable `ISInventoryPaneContextMenu.unequipItem` is a silent no-op unless `playerObj:isEquipped(item)` is already true — including while that item's `ISEquipWeaponAction` is still queued.**

Found S123. Firing UNEQUIP 120 ticks after EQUIP on a baseball bat did nothing because the equip had not landed yet; the bat ended up equipped. Tests (and any auto-chained verbs) must wait for the equip action to complete, or check `ISTimedActionQueue.getTimedActionQueue(player).queue[1].Type` before firing.

---

**Q125–Q128 answered (S123 live probes on stable 42.20.2, `Base.Trousers_Denim` / `Base.Steak`).**

- **Q125** `item:getInsulation()` and `item:getScriptItem():getInsulation()` both exist; 0–1 float (jeans 0.70). Stable per frame.
- **Q126** Wind resistance is `item:getWindresistance()` — lowercase **r**. `getWindResistance` does not exist on the item, and the script item has no wind getter at all. `item:getWaterResistance()` exists (0 on jeans).
- **Q127** Food cooking getters: `getCookingTime()` (minutes accumulated on heat, starts 0), `getMinutesToCook()` (steak 50), `getMinutesToBurn()` (steak 70), `isCooked()`, `isBurnt()`, `isCookable()`. No `getCookedTime` / `getCookedDate`.
- **Q128** `setCookingTime(n)` alone never flips `isCooked`/`isBurnt` — those flags are set by the Java cooking update while the item sits in an **activated heat source container** (stove/fire). So the danger window for the Progress Band is: `isCooked()` true (or `getCookingTime() >= getMinutesToCook()`) and not yet `isBurnt()`; burn progress = `(cookingTime - minutesToCook) / (minutesToBurn - minutesToCook)`. Cooking is **not** a TimedAction — nothing appears in `ISTimedActionQueue` — so it needs its own poll of the carded item's container parent (`container:getParent()` → `IsoStove`/fire, `:Activated()`).

---

**Q132–Q137 (S123 evening, v5 HUD build, stable 42.20.2 live probes).**

- **Q132** `getCell():getVehicles()` returns a `java.util.HashSet` in B42. `size()` works, `get(i)` is nil ("Object tried to call nil"); vanilla `ISVehicleBloodUI` still indexes it and is broken. Iterate with `:iterator()` / `hasNext()` / `next()`.
- **Q133** `UIManager.getClock()` and `UIManager.getSpeedControls()` are rendered by Java regardless of `setVisible(false)` (the flag reads back false while both still draw). Java re-aligns their X every frame (right edge) but leaves Y alone, so park them at `setY(-4000)`; the speed controls follow the clock's Y automatically. The B42 clock also prints the air temperature - parking it removes that readout.
- **Q134** `addVehicleDebug(script, dir, nil, square)` needs a real `IsoGridSquare` as the 4th argument (nil -> NPE "sq is null" in `LuaManager$GlobalObject.addVehicleDebug`). Entering (`vehicle:enter(seat, chr)`) a vehicle whose physics is not active (beyond the simulation radius, ~35 tiles in the test) throws a `BaseVehicle.updatePhysics` NPE inside `IngameState.update` and the engine exits to the MAIN MENU with no dialog. Distance-check first; `vehicle:permanentlyRemove()` cleans up debug spawns.
- **Q135** Kahlua strings are Java strings: `string.char(183)` is the middle dot; UTF-8 byte pairs (`"\194\183"`) render as two glyphs. `TextManager:MeasureStringX(font, x)` requires a String - a number throws "expected argument of type String, got Double" (every frame if it sits in prerender).
- **Q136** `console.txt` restarts mid-session once it grows large (seen after ~70k lines); `logs/<date>_DebugLog.txt` carries the Java log but no Lua `print` lines. Read bridge output right after each run.
- **Q137** `getCore():TakeFullScreenshot("name.png")` writes a native-resolution PNG to `Zomboid/Screenshots/` synchronously from Lua - the way to inspect pixels from bridge scripts.

---

**Q138–Q140 (Oct 13 2026, UI scale probes on stable 42.20.2).**

- **Q138** `ISUIElement:drawTextZoomed(str, x, y, zoom, r, g, b, a, font)` (Java `UIElement.DrawText(font, str, x, y, zoom, ...)`) scales text continuously - 1x, 1.37x, 2x, 2.5x, 3x all render in one call and `MeasureStringX(font, str) * zoom` is the exact drawn width. Bitmap atlases blur past ~1.4x.
- **Q139** Fonts are SDF per slot through `media/fonts/EN/fonts.txt`: an entry `font Name { fnt = file.fnt, type = sdf, }` makes ANY slot a distance-field font (shader `media/shaders/sdf.frag`, alpha thresholded at 0.5). Vanilla ships Open Sans (SdfRegular/Bold/Italic/BoldItalic), Old Standard TT (SdfOld*), Caveat and RobertoSans; the map labels use SdfBold/SdfBoldItalic, print media the Old family, PZAPI atoms SdfRegular. SDF text zoomed 3x-4x stays crisp.
- **Q140** The engine font-size option (`getOptionFontSize`, `getOptionFontSizeReal` - 2 on the 4K rig) does not change ZeD's bitmap fonts: the live `Small` slot measures the 1x face (line height 17 for the 13px body). The mod's `EN/2x,3x,4x` folders are not consulted for its slots. Treat the option as a user preference to read, not as a scale source. Also: `getCore():TakeFullScreenshot` writes an all-white frame while the fullscreen window is minimized.

- **Q141** (S124) Distance-field fonts in practice: `drawText` / `drawTextZoomed` (UIElement -> TextManager -> AngelCodeFont) NEVER bind the SDF shader - only the PZAPI text atoms (`AtomUIText`, `AtomUITextEntry`) and the world map do (javap on the jar). A slot flagged `type = sdf` is drawn at the atlas's native face size at zoom 1 (a 32 px face measures 32 px glyphs) with its alpha ramp blended RAW: the ±spread texel ramp becomes ±(spread x zoom) screen px, so a 32 px / spread 4 atlas is crisp at ~0.4x, soft at 1x, a blob at 2x, and strokes never reach full opacity. Consequence for ZeD: bake faces at ~2.5x the largest common draw size with a tight ramp (64 px face, spread 2 - `bake_sdf.py --spread 2`), which measures near-ideal anti-aliasing at 13 and 26 px on that path; spread 4 is only right if the shader path is ever used (its threshold = 0.125 / scale). The manifest keys `size =` and `zoom =` the parser knows had no effect on these slots; `MediumNew` ignores the manifest (falls back to the vanilla font); `MainMenu1/2`, `Title`, `Massive`, `Cred1/2` accept it.

- **Q142** (S124) Scaling a Lua UI without touching every call site: `ISUIElement.drawText / drawTextRight / drawTextCentre / drawRectBorder` can be replaced at the class table (vanilla classes inherit through the metatable chain, so one patch covers every element); gate the behaviour on the font (only ZeD's distance-field slots zoom) and on a class flag (`zedScaled = true` set on the ZeD classes via `_G[name]` at load and again on `OnGameBoot`), so the vanilla UI keeps its original calls. Measurements cannot be patched on the Java `TextManager`; a Lua proxy (`ZeD.TM`, `__index` passthrough to the real manager) stands in for `getTextManager()` in the mod's own files. A root-scale change at runtime needs open windows re-derived from design units: close the pair first (its close path persists geometry divided by the old scale), apply the new tokens, reopen a few ticks later. The game's Kahlua compiler can be driven from the jar for a compile-only syntax check (`KCheck.java` in the session scratchpad; `jre64/bin/java -cp projectzomboid.jar;. KCheck <files>`), which caught nothing wrong across ~1,350 edits but costs seconds instead of a two-minute save reload.


**Q143–Q147 (Oct 13 2026, Vehicle tab build on stable 42.20.2).**

- **Q143** `getTexture("media/textures/<mod path>/<name>.png")` can resolve to a VANILLA packed texture that shares the base file name: baked `4door_hood.png` came back 113x93 (vanilla's trimmed overlay) instead of the mod's 107x89 file. Give mod textures a unique prefix (ZeD uses `zm_` for the mechanics figures).
- **Q144** Inside a World window tab renderer, anything drawn after the renderer function returns (or at its very end, after the body stencil was set and cleared) did not appear on screen, while draws earlier in the same function did. Paint focus cues inline at the moment each element is drawn (ZeD's `stamp()` paints the 0.55 accent fill right after the element).
- **Q145** Kahlua has no `next()`; test table emptiness with a `for _ in pairs(t) do ... break end` loop.
- **Q146** `VehicleUtils.getItems` / `getContainers` read the vanilla inventory and loot pages' `backpacks` lists. Those pages stay alive and refreshed while ZeD hides them (2 inventory pages, the floor + adjacent containers on loot), so vanilla install / uninstall / repair find tools in bags. A vehicle's trunk is only listed while the player stands at the trunk area (vanilla behaviour).
- **Q147** `ISOpenMechanicsUIAction:perform` is the single funnel for every vanilla way into the mechanics window; `ISVehicleMechanics:setVisible` also toggles `vehicle:setMechanicUIOpen` and `setActiveInBullet`, so a replacement must call those itself. Install / uninstall results arrive on `Events.OnMechanicActionDone(chr, success)`. QA hazard: a character boxed in by parked vehicles fails every path (`ISWalkToTimedAction` ends in 4 ticks with no movement); a locked debug car needs `createVehicleKey()` before vanilla can pop the hood.
- **Q148** (Oct 13) `PZAPI.ModOptions` combo-box `addItem(name)` stores `getText(name)`; a label containing `%` makes `getText` return nil and the load dies with `Not enough arguments at table.insert` (the whole options file stops registering). Keep `%` out of option labels and tooltips. `addSlider(id, name, min, max, step, value, tooltip)` also exists.

**Q149–Q155 (Oct 13 2026, crafting stations build on stable 42.20.2).**

- **Q149** Station entry points: `ISEntityUI.OpenWindow(player, entity)` is the one call behind the world right-click station option (`ISContextEntity.openPanel`), the controller Interact prompt (`ISButtonPrompt:openEntityUI`) and clicking a multi-tile master (`ISObjectClickHandler`); all look it up at call time, so replacing the table field routes every caller. The crafting and build keys (`XpUpdate`), the HUD buttons, the controller wheel, item-menu "craft" entries and recipe books all go through `ISEntityUI.OpenHandcraftWindow` / `OpenBuildWindow`. Oven and microwave settings end in `ISOvenUITimedAction:perform`.
- **Q150** Benches are entities with a `CraftBench` component (`entity:getComponent(ComponentType.CraftBench)`); `craftBench:getRecipes()` is the bench's recipe list. Drying racks carry `ComponentType.DryingCraftLogic` (a `CraftLogic`) plus `Resources`. `recipe:requiresSpecificWorkstation()` + `recipe:getTags()` name the station: vanilla's label is `getText("IGUI_CraftingWindow_" .. tag)`. A bench craft needs `isoObject:isUsingPlayer(player)` (`ISHandcraftAction:isValid`): take the lock with `entity:setUsingPlayer(player)` and release it with `nil`.
- **Q151** A drying rack's input `ResourceItem:acceptsItem` returns true for ANY item while empty, then only the loaded type. What "fits" comes from the rack's recipes (`craftLogic:getRecipes()` -> `getInputs()` -> `getPossibleInputItems()`). One drying craft consumes the whole stack (`item variable[1:20]`), and `stop(player)` returns the items to the input slot.
- **Q152** `CraftLogicUILogic:getItemsInProgress()` returns `{ CraftRecipeData -> { script Item -> count } }` where the count is a Java number: `tonumber(count)` is nil in Kahlua, `tonumber(tostring(count))` works. Progress per craft is `craftLogic:getProgress(craftRecipeData)` (0..1); recipe `getTime()` is game seconds (86400 = one day of drying).
- **Q153** In B42 the stove settings and stove on/off live only on the loot window's container buttons (`LootWindow/Handlers/StoveSettings`) and the inventory-pane menu over a stove container. With the vanilla loot window hidden, ovens had no settings surface until the Craft tab's appliance view. Settings writes: `setMaxTemperature(c)`, `setTimer(seconds)`, then `sync()` + `syncSpriteGridObjects(false, true)`; on / off goes through `sendClientCommand(player, 'stove', 'setOvenParamsAndToggle', {x, y, z, timer, maxTemperature})`. A fresh stove reports `getTimer() == -1`.
- **Q154** Child ISPanels paint after their parent's `render`, so an overlay drawn inside a tab renderer (a dropdown) sits UNDER child panels such as a search field. Hide the child for that frame (`setVisible(false)` during the parent render; the next prerender shows it again).
- **Q155** QA spawning: `ISBuildIsoEntity:new(player, objectInfo, nSprite, containers)` + `:create(x, y, z, north, nil)` places any entity under build cheat, but `create` reads `self.player` (a player NUMBER the drag cursor normally sets): set `b.player = player:getPlayerNum()` first. `create` returns false on an invalid square (bushes, a blocked second tile). Find the info by `info:getScript():getParent():getScriptObjectFullType()` (e.g. `Base.Kiln_Small`). `player:teleportTo(x, y, z)` moves the character. Bench craft outputs drop to the floor when the character is over the carry limit.

- **Q156** (Oct 13) `UITextBox2` (the Java box under `ISTextEntryBox`) draws its font at the font's native pixel size: no zoom, only `setFont(UIFont)` (plus `setCentreVertically`, `setTextRGBA`, `setPlaceholderText` / `setPlaceholderTextRGBA`, which draws the placeholder in the same font). `ISTextEntryBox` reads `self.font` only in `instantiate`; setting `entry.font` afterwards does nothing, use `entry:setFont(f)`. The engine fills `MediumNew` and `AutoNormSmall/Medium/Large` itself (`TextManager`, the zomboidNormal faces): a mod manifest entry for those slots is ignored and they measure like `Small`. Mod-assignable spare slots (in the vanilla manifest, named by no vanilla Lua, script or game class): `SdfItalic`, `SdfOldRegular`, `SdfOldItalic`, `SdfOldBoldItalic`, `SdfRobertoSans`, `SdfCaveat`; re-declared without `type = sdf` they load as plain bitmap faces. `getFontHeight` of a bitmap face reports about 1.3x its `.fnt` size (13 px body -> 17, 15 -> 20, 26 -> 32). Font manifests load at game start only: a font change needs a full restart, not quit-to-menu.

**Q157–Q162 (Oct 13 2026, object cards build on stable 42.20.2).**

- **Q157** Generator fuel: `getFuel()` / `getMaxFuel()` are litres (10 L tank). `getTotalPowerUsing()` and `getBasePowerConsumption()` already multiply by `SandboxOptions.generatorFuelConsumption` (default 0.1), and `IsoGenerator.update` burns `totalPowerUsing x generatorFuelConsumption` per game hour, so `getFuel() / getTotalPowerUsing()` is the run time left in game hours. An idle generator draws 0.002 L/h (base 0.02 x 0.1): a few litres last months. `getItemsPowered()` is an ArrayList of `"Name (#.#### L/h)"` strings (factor applied). `getGeneratorItemType()` names the script item (`Base.Generator`...) for a display name and icon. Spawn for QA: `IsoGenerator.new(instanceItem("Base.Generator"), getCell(), square)`; on / connected / fuel through `setActivated`, `setConnected`, `setFuel`.
- **Q158** Vanilla's campfire Info option passes the Lua campfire (`CCampfireGlobalObject`) where `ISCampingMenu.onDisplayInfo` and `ISCampingInfoAction` expect the IsoObject; resolve through `getSquare()` + `CCampfireSystem.instance:getLuaObjectOnSquare(sq)`. A campfire's `fuelAmt` is minutes and `isLit` a boolean on the Lua object (`updateFromIsoObject()` refreshes them from the IsoObject's mod data); its container (`getIsoObject():getContainer()`, type `campfire`) is filled with loot on creation (twigs, branches, a bottle), and `ISCampingMenu.getNearbyFuelInfo` counts that container as nearby fuel. `getCampingFuelMax()` lives in `server/Camping/camping_fuel.lua` (minutes = `MaximumFireFuelHours x 60`). QA spawn: `SCampfireSystem.instance:addCampfire(square)`.
- **Q159** `ISFarmingMenu.onInfo` (and onWater / onSeed / onHarvest / cures / onShovel / onFertilize) queue the timed action only for a mouse player and then arm an `ISFarmingCursorMouse` "click another square" drag; for a controller player only the cursor is armed. A replacement surface should queue `ISWaterPlantAction`, `ISSeedActionNew`, `ISCurePlantAction` (`cure` = "Mildew" / "Flies" / "Slugs" / "Aphids"), `ISHarvestPlantAction`, `ISShovelAction`, `ISFertilizeAction` itself after `ISFarmingMenu.walkToPlant`. Vanilla's `predicateGoodSeed` is local; copy it. QA spawn: `SFarmingSystem.instance:plow(square)`, then `SFarmingSystem.instance:getLuaObjectAt(x, y, z):seed("Carrots")`, set fields, `growPlant(obj, nil, true)` and `saveData()`; `player:setPerkLevelDebug(Perks.Farming, n)` for the skill gates.
- **Q160** After `ISShovelAction` the client `CFarmingSystem` still returns the plot's Lua object on that square for a moment while `getIsoObject()` is already nil: filter scans on `getIsoObject() ~= nil`.
- **Q161** The vanilla Info handlers walk adjacent first; when no adjacent tile is reachable (`luautils.walkAdj` fails) nothing is queued and nothing is said. The same holds for the barbecue toggle and every walk-adjacent action a card verb calls.
- **Q162** `javap` is available at `C:/Program Files/Java/jdk-19/bin/javap.exe`: `javap -c -p -cp <extracted jar dir> zombie.iso.objects.IsoGenerator` disassembles game classes (how fuel, draw and the sandbox factor combine was read this way).

**Q163–Q166 (Oct 13 2026, fluid card build on stable 42.20.2).**

- **Q163** `FluidContainer.CanTransfer(from, to)` refuses any pour into an `InventoryItem` held by a player whose `hasFullInventory()` is true (over the carry limit), and `GetTransferReason` then falls through to its last line, `Fluid_Reason_Mixing_Locked` ("Cannot mix these liquids."), which is misleading. Check `player:hasFullInventory()` for a carried target to name the real reason. The other reasons, in order: source / target null, equal, source empty, target full, target input locked, target white/blacklist filter.
- **Q164** A container's liquids are a private `FluidInstance` list. From Lua: iterate `Fluid.getAllFluids()` and read `fc:getSpecificFluidAmount(fluid)`; `fluid:getTranslatedName()`, `fluid:getColor()` (a `Color`, `getRedFloat()`...), `fluid:isPoisonous()`, `tostring(fluid:getFluidType())` ("TaintedWater"). `fc:getUiName()` adds the container and "(Tainted)" ("Water (Rain Collector) (Tainted)"). Outside debug, vanilla's fluid tooltip shows only a red "Tainted" (`Tooltip_tainted`) when `fc:isPoisonous()` with a non-None `getPoisonEffect()` and either a poisonous liquid other than tainted water or tainted water with `SandboxVars.EnableTaintedWaterText`; the poison level (`Fluid_Poison_<Effect>`) and properties are debug-only. Pours run at `FluidUtil.getTransferActionTimePerLiter()` = 40 ticks per litre (minimum 20); `FluidUtil.roundTransfer(x)` is vanilla's Max Pour rounding.
- **Q165** `ISBaseTimedAction:getJobDelta()` indexes `self.action` (the Java action), which exists only after the action has started; a queued pour still walking errors. Guard on `act.action`. The Lua debugger's Break On Error halts the game even for errors inside `pcall`.
- **Q166** QA spawn of a world fluid container: `Base.RainCollector` (400 L) through `ISBuildIsoEntity` (Q155), then `obj:getFluidContainer():addFluid(Fluid.TaintedWater, n)`. Items: `Base.WaterBottle` (1 L), `Base.Pot` (1.5 L), `Base.Mugl` (0.2 L), `Base.Bucket` (10 L), `Base.Bleach`, `Base.PetrolCan`; `fc:Empty()` then `fc:addFluid(Fluid.Water, l)`.

**Q167–Q172 (Oct 14 2026, Furniture tab build on stable 42.20.2).**

- **Q167** `ISMoveableCursor` and `ISBuildingObject` live in `media/lua/server/BuildingObjects/`, which loads with the save (after client `OnGameBoot`). Client hooks on them install at `OnGameStart` or lazily on a tick once the class exists.
- **Q168** The furniture cursor's info: `ISMoveableCursor:isValid(sq)` calls `setInfoPanel(sq, obj, moveProps, tex)` every frame and it returns the `ISMoveableInfoWindow`; its lines are `infoPanel.bodyText.table`, each `{ [1] = { txt, r, g, b }, [2] = {...} }` with colours 0..1 after `setBodyText`. Label + value lines; an empty label continues the previous fact (more acceptable tools); debug-only lines are magenta plus a grey DEBUG ... END DEBUG block. Modes in `ISMoveableCursor.mode[pn]` (pickup, place, rotate, scrap, repair); `setMoveableMode`, `objectIndex`, `objectListCache` (pickup / scrap / repair arrays of `{object, moveProps}`, rotate a single table), `exitCursor()`, `getCell():setDrag(cur, pn)`.
- **Q169** The cursor follows the mouse over UI. Java calls the global `DoTileBuilding(cursor, isRender, x, y, z, square)` with the tile under the mouse (it calls `isValid` and `render`), and `ISMoveableCursor:beforeWorldRender` passes nil when vanilla's `isMouseOverUI()` is true. `isValid` resets `objectIndex` to -1 (pickup, rotate) on any new square and clears `cursorFacing` / `joypadFacing` on a nil square. Clicks over UI never act: `isBuildButtonDown` reads the Attack binding with `isKeyDownInWorld`.
- **Q170** Faces: `ISMoveableSpriteProps:getIndexedFaces()` fills slots 1 N, 2 W, 3 S, 4 E and pads a missing face with the opposite one (a pottery wheel with only S and E gives `{S, E, S, E}`), and `getFaceIndex()` returns the first matching slot, so it cannot tell N from S on such objects. `getFaces()` gives the real set. `cursorFacing`, `joypadFacing` and rotate's `objectIndex` use the same slots (vanilla's direction table is `{N, W, S, E}`).
- **Q171** `canRotateMoveable` checks the whole sprite grid for multi-tile objects (half a couch alone never turns) and fails when the turned grid would land on a blocked tile (a parked car). Repair lists only objects with health (`obj.getHealth`: built and crafted things) and a valid repair material. QA furniture: `IsoObject.new(sq, sprite, name)` + `sq:AddTileObject(o)`; `furniture_seating_indoor_02_0` is a single-tile Mahogany Chair with four faces; `furniture_seating_indoor_01_*` are couches (two tiles).
- **Q172** Vanilla `ISEquippedItem:prerender` re-shows `movableBtn`, `movableTooltip` and `movablePopup` every frame; hiding them takes a per-frame `setVisible(false)` after the original prerender. Extended 3D Placement: world item `setOffX/Y/Z` (0..1) and item `setWorldX/Y/ZRotation` (0..360) with `setExtendedPlacement(true)`; gizmo `Gizmos.getInstance():getTranslateGizmo(pn) / getRotateGizmo(pn)`, `setWorldPosition`, `setRotation`, `setVisible`, `setTable(t)` (callbacks `onTranslateGizmo(self, v)` / `onRotateGizmo(self, v)`), `setGizmo(pn, g)`; close with `setDoingExtendedPlacement(false)`, `syncExtendedPlacement()`, `setGizmo(pn, nil)`. `ISWorldObjectContextMenu.onExtendedPlacement(worldItem, player)` queues `ISExtendedPlacementAction` (walk, then perform); vanilla offers it to mouse players only.

**Q173–Q175 (Oct 14 2026, controller 3D placement on stable 42.20.2).**

- **Q173** The world menu's grab block, and "Extended 3D Placement" in it, is built in Java: `ISWorldObjectContextMenuLogic.handleGrabWorldItem`. The 3D option is skipped when `LuaHelpers.getJoypadState(playerNum)` is non-nil (the player has a controller assigned, `JoypadState.players[pn+1]`). An item qualifies when its `IItemProvider:getItem()` has `getWorldStaticItem()` or `getClothingItem()`, or is a `HandWeapon`; a wall between the item's square and the player's (`isWallTo`) drops it. The option calls `ISWorldObjectContextMenu.onExtendedPlacement(worldItem, player)` (`luautils.walkAdj`, then `ISExtendedPlacementAction`). A controller's world menu comes from `ISButtonPrompt:interact` -> `ISContextManager.createWorldMenu` with the first object of up to four squares around the player; `OnFillWorldObjectContextMenu` handlers should return `ISWorldObjectContextMenu.setTest()` when `test` is true and they have something to add.
- **Q174** `getControllerAxisValue(i, 4 / 5)` (triggers) on an XInput pad seen through GLFW ("XInput Gamepad (GLFW)") reads -1.0 when released. Never `abs()` a trigger axis: measure the pull from the resting value. `getControllerCount()` reported 16 slots with one connected.
- **Q175** Right-clicks and clicks on UI do not fire `Events.OnMouseDown` (world clicks do), so a detector that switches to keyboard / mouse on `OnMouseDown` only flips on a world click or a key press.

**Q176–Q181 (Oct 14 2026, animal cards on stable 42.20.2).**

- **Q176** Vanilla's timed-action queue drops whatever is queued behind a finished `ISHutchGrabEgg` (seen with two grabs queued back to back: the second never starts, no error). Vanilla's window queues one box per click. To take several boxes, queue the next one once the player is idle.
- **Q177** Butcher hook: the actions (`ISPutAnimalOnHook`, `ISRemoveAnimalFromHook`, `ISCutAnimalOnHook`, `ISGatherBloodFromAnimal`, `ISRemoveLeatherFromAnimal`, `ISRemoveHeadFromAnimal`, `ISRemoveMeatFromAnimal`) take a `luaHookUI` and use: fields `hook`, `doingAction`, `actionText`; methods `updateProgressBar(p)`, `updateCorpseDatas()`, `onAddedCorpse(corpse)`, `onClickRemoveCorpse()`, `resetCorpse()`, `getBuckets()`. Java calls `ISButcherHookUI.onStopBleedingAnimal(luaHook)` (reads `luaHook.progressBar.progress`) and `ISButcherHookUI.onHookReceivedNetUpdate(luaHook)` on whatever `hook:setLuaHook` holds. `ButcheringUtil.updateCorpseDatas(t, animal, hook)` fills `t.leather / blood / head / meat` from the carcass mod data and calls `t:onClickRemoveCorpse()` when nothing is left (skeleton). Taking the meat sets `BloodQty` to 0 (the blood is lost); taking the head splashes it but keeps it. Blood containers are `inventory:getAvailableFluidContainer("AnimalBlood")` (a gas can counts). The hooked carcass is an `IsoAnimal` (`getFullName()` "Angus Cow"); `ButcheringUtil.getCarcassName` returns a type key ("cowangus"). `ISCharacterScreenAvatar` works as a child of any ISPanel with vanilla's setup sequence (zoom / offsets from `AnimalAvatarDefinition[type].butcherHook*`, `setVariable("onhook", true)`, `setDirection(NE)`, `setIsometric(false)`, `setAnimSetName`, `setCharacter`).
- **Q178** Hutch: `IsoHutch:getHutch()` is the master; `getEntrySq()`, `isOpen()`, `isEggHatchDoorOpen()`, `isAllDoorClosed()`, `getNestBox(i)` (0..`getMaxNestBox()`), `getAnimalInNestBox(i)`, `getAnimal(i)` (0..`getMaxAnimals()`-1, sparse), `getAnimalInside()`, `getDeadBody(i)`, `getHutchDirt()`, `haveRoomForNewEggs()`. The hutch type is a public Java field Lua cannot read: match the tile against `HutchDefinitions.hutchs[k]` sprites and use `ContextMenu_Hutch_<k>` (Henhouse, Turkeyhouse). Hens leave through an open door in daytime. `IGUI_Hutch_Dirt` has a `%1`: reading it with `getTextOrNull` (no argument) logs `Translator.reportMissingArgumentsFromPastAbuse` every frame.
- **Q179** Feeding trough: `getMasterTrough()`; the food is the object's `ItemContainer` and `isItemAllowedInContainer(container, item)` accepts far more than feed bags (herbs, eggs, hay, grass); `getCurrentFeedAmount()`, `getWater()` / `getMaxWater()` in litres; `getLinkedAnimals()`; the zone is `DesignationZoneAnimal.getZone(x, y, z)`. A zone lists its structures with `getTroughsConnected()` and `getHutchsConnected()`. The trough's fluid container calls itself "Liquid Container". Vanilla's debug `ISFeedingTroughMenu.onAddFoodDebug` errors (`addItems` of nil) on a fresh trough.
- **Q180** Animal tracks are made from a `VirtualAnimal` (`AnimalTracks.addAnimalTrackAtPos`); `VirtualAnimal` is not exposed to Lua, so QA cannot plant tracks. `AnimalTracks.getNearestTracks(x, y, r)` lists existing ones.
- **Q181** QA yard spawns: `Base.ChickenHutch`, `Base.FeedingTroughDoubleMetal` (it places as a Small Metal Trough), `Base.ButcherHook` through `ISBuildIsoEntity` (Q155); animals with `addAnimal(getCell(), x, y, z, type, AnimalDefinitions.getDef(type):getBreeds():get(0))` (`setHealth(0)` makes a corpse); `hutch:addAnimalInside(a)`, `hutch:addAnimalInNestBox(a)`, `nest:addEgg(instanceItem("Base.Egg"))`, `hutch:setHutchDirt(n)`; a carried bird is `instanceItem("Base.Animal")` + `setAnimal(a)` in both hands; feed items `Base.HayTuft`, `Base.GrassTuft`, `Base.AnimalFeedBag`.

**Q182–Q187 (Oct 14 2026, animals in trailers on stable 42.20.2).**

- **Q182** A character's `getHealth()` is 0-1, animals included (`IsoGameCharacter.health`, 1.0 = healthy, `setHealth(0)` kills). ZeD's `AnimalsData.getHealth` now scales it to 0-100 like hunger and thirst.
- **Q183** Trailer API on `BaseVehicle`: `getAnimalTrailerSize()` (500 on `Base.Trailer_Livestock`, 0 on other vehicles), `getAnimals()` (a live `ArrayList<IsoAnimal>`; a dead animal stays an `IsoAnimal` with `isDead()`), `getCurrentTotalAnimalSize()`, `canAddAnimalInTrailer(animal | deadBody)`, `addAnimalInTrailer(animal | deadBody)` (does NOT check the space: QA forced 618 of 500), `addAnimalFromHandsInTrailer(...)`, `removeAnimalFromTrailer(a)` (returns a new world object), `getAnimalById(id)`. An animal takes `animal:getAnimalTrailerSize()` (a ewe 89.6, a ram 88, a lamb 56, a hen 22, an adult cow ~310-340); a carcass `body:getModData().animalTrailerSize`. `animal:getAnimalID()` identifies it across frames; a carcass keeps `AnimalType` / `AnimalBreed` in its mod data. `getStats():set(CharacterStat.HUNGER | THIRST, v)` works on animals.
- **Q184** Vanilla's trailer flow: the world menu and the vehicle wheel call `ISVehicleMenu.onCheckAnimalInside(vehicle, player)` (walkAdj to the `AnimalEntry` area centre, then `ISCheckAnimalInsideTrailer`, whose perform opens `ISVehicleAnimalUI`). Only the menus check the lid (`TrunkDoor` / `DoorRear` / `TrunkDoorOpened` door open, "Trunk door is closed."); `ISRemoveAnimalFromTrailer` and `ISAddAnimalInTrailer` do not. Vanilla bugs: `ISVehicleMenu.onRemoveAnimalFromTrailer` queues the action without the animal (does nothing); `doAnimalSubMenu` never sets `added` for a carcass in the hands. Water / feed for a trailer animal: `AnimalContextMenu.onGiveWater` / `onFeedAnimalFood` already walk to the back for an animal whose `getVehicle()` is set.
- **Q185** `animal:canBePicked(player)` is true for any animal while the player has god mode (a QA artefact: an adult cow became grabbable); without it the cow refuses ("Animal is too heavy to be picked up.").
- **Q186** The trailer's Food Container (`TrailerAnimalFood`, 20) and Egg Container (`TrailerAnimalEggs`, 10) use `Vehicles.ContainerAccess.TruckBed`: the player inside the `TrailerAnimalFood` area and the lid open (or the lid item removed). Vanilla names vehicle containers `getText("IGUI_VehiclePart" .. container:getType())`. `setVehicleTowing(v, a, b)` / `setVehicleTowedBy(v, a, b)` only set fields; with no physics constraint (`constraintTowing == -1`) the attach checks skip, so QA can link two vehicles for UI work; the link does not survive a reload when made this way.
- **Q187** `ISVehicleAnimal3DModel` (an `ISUI3DModel`, non-isometric, eats no clicks) works as a child of any panel: `setAnimSetName(a:GetAnimSetName())`, `setCharacter(a)`, then per frame vanilla's trailer framing `AnimalAvatarDefinition[type].trailerZoom / trailerXoffset / trailerYoffset` times `a:getData():getSize()`, `trailerDir`, `setVariable("TrailerAnimation", dead and "dead" or "idle1")`. A child keeps drawing when the parent stops calling into it, so ZeD's figure checks a last-placed timestamp in its own prerender and hides itself.

**Q188–Q192 (Oct 14 2026, padlock codes on stable 42.20.2).**

- **Q188** The world menu's padlock options are built in Java (`zombie.iso.ISWorldObjectContextMenuLogic.doPadLockMenu`) and call Lua by name through `LuaManager.getFunctionObject("ISWorldObjectContextMenu.onPutDigitalPadlock")` (also `onRemoveDigitalPadlock`, `onPutPadlock`, `onRemovePadlock`), so replacing those table fields reroutes them. Only an `IsoThumpable` that is not a door qualifies: `canBeLockByPadlock()` (entity scripts with `canBePadlocked = true`: wooden and metal crates, small and big metal lockers, metal counters, bar elements), not `isLockedByPadlock()`, `getLockedByCode() == 0`; the Combination Padlock and the Padlock are looked up with `ItemContainer.FindAndReturn` on the main inventory (vanilla's actions remove them from there).
- **Q189** Code locks: `setLockedByCode(n)` / `getLockedByCode()` (0 = none); `isLockedToCharacter(chr)` is true for EVERY character while a code lock is on (its owner included; admins with `CanOpenLockedDoors` excepted), and for a key padlock unless `inventory:haveThisKeyId(obj:getKeyId())`. `ISPadlockByCodeAction:new(chr, thump, padlock, lock, code)` (20 ticks): lock removes the padlock and sets the code; unlock only acts when the code matches (otherwise it completes doing nothing), returning a new `Base.CombinationPadlock`. `ISDigitalCode` refuses 000 silently, is titled "Set your Code" on removal too (`new = true` passed), its B button presses OK, and its `destroy` resets the game speed to 1.
- **Q190** Key padlocks (`ISPadlockAction`, 20 ticks): putting one on sets `setLockedByPadlock(true)` and the padlock's key id on the object and adds `getNumberOfKey()` `Base.KeyPadlock` keys; removing needs a key, returns a `Base.Padlock` holding one key (the key item is consumed). A Padlock item is itself a Key: `haveThisKeyId(id)` finds the padlock afterwards.
- **Q191** A built entity's display name is `obj:getEntityDisplayName()` (from its xui skin entity style, e.g. "Small Metal Locker (Basic)"); `getName()` is the entity id ("Metal_LockerSmall_Lvl1").
- **Q192** Key events reach Lua UI only on top-level elements: `UIManager.onKeyPress` walks the UI list and, for a visible element with `isWantKeyEvents()`, calls `onConsumeKeyPress(key)` = Lua `onKeyPress(key)` then `isKeyConsumed(key)`; a consumed key never reaches `Events.OnKeyPressed` (the hotbar's number keys stay quiet). Kahlua's `%` follows Java's remainder for negatives (`-1 % 10 == -1`, standard Lua gives 9).

**Q193–Q197 (Oct 14 2026, the belt on stable 42.20.2).**

- **Q193** `ISUIElement:setX / setY` clamp a TOP-LEVEL element (no parent) onto the screen: `getKeepOnScreen()` is `self.keepOnScreen` or `not self.parent`. Parking a top-level panel at -10000 lands it at 0, 0, invisible but still catching clicks; set `self.keepOnScreen = false` first.
- **Q194** `ISContextMenu.get(player, x, y)` returns the player's one reused menu and does not reset fields a mod stamps on it; anything keyed off the last menu (anchor, target) leaks into the next one built straight on `get` (vanilla `ISHotbar:doMenu`, Journal, Maps). ZeD resets its anchor and target inside a `get` wrapper.
- **Q195** A ZeD context menu opened on a left mouse DOWN closes on that click's release (`onMouseUpOutside` -> cancel). Buttons that open a menu must act on release.
- **Q196** Vanilla hotbar: `availableSlot[i] = { slotType, name, def, texture }`, `attachedItems[i]`; `attachItem(item, slotDef.attachments[item:getAttachmentType()], i, slotDef, doAnim)` queues `ISAttachItemHotbar` (onto a filled slot it detaches the old item first); `removeItem(item, doAnim)`; `activateSlot(i)` toggles lights and walkies, else `equipItem` (an item in the hotbar going out of the hands returns to its slot); `isAllowedToActivateSlot()` is false while paused, attacking, the radial is up or any action is queued. Key handlers are added in `OnGameStart` (`Events.OnKeyStartPressed / OnKeyPressed / OnKeyKeepPressed`); `keyPressedMS` marks the press for the 500 ms hold. Queuing two `ISAttachItemHotbar` for the same item stalls the queue at delta 0.
- **Q197** `ISToolTipInv` stands at a fixed point with `followMouse = false` and `anchorBottomLeft = { x, y }` (its bottom-left corner); otherwise it follows the pointer.

**Q198–Q204 (Oct 14 2026, moodles on stable 42.20.2).**

- **Q198** `MoodlesUI` (one per player, `UIManager.getMoodleUI(pn)`; four exist, the unused ones invisible): the engine puts its x back at screen right - (10 + size) every frame before the UI draws (y only in split screen; `UIManager.resize` sets y = 120 + the player's top). A move must be made in `Events.OnPreUIDraw`; a setX anywhere earlier never reaches the screen. Its element is size wide and screen-height tall. It draws a backing (`media/ui/Moodles/<size>/_Moodles_BGsolid.png`) tinted by `Color.lerpABGR(gray, Core.getGood/BadHighlitedColor(), level / 4)`, the outline `_Moodles_BGoutline.png`, then the icon; no chevrons and no pulse in this build (the chevron data in `Moodle` / `Thermoregulator.thermalChevronUp/Count` is drawn by nothing). Hover text is drawn to the LEFT of the column. Size: `getCore():getOptionMoodleSize()` 1-6 -> 32/48/64/80/96/128 px (7 = from the font size). Wiggle on a level change: x offset sin(step) * 15.6 * level, step += 0.8 * 0.5 * ms/33.3. FOOD_EATEN only shows from level 3.
- **Q199** `MoodlesUI`'s slot order is the iteration order of its `HashMap<MoodleType, ...>`: `MoodleType` does not override hashCode, so the order changes every launch. It can be reproduced from Lua: `MoodleType.X:hashCode()` is callable; 26 entries end in 64 buckets, bucket = (h ^ (h >>> 16)) & 63 (h as unsigned 32-bit), ties in registration order (Endurance, Tired, Hungry, Panic, Sick, Bored, Unhappy, Bleeding, Wet, HasACold, Angry, Stress, Thirst, Injured, Pain, HeavyLoad, Drunk, Dead, Zombie, Hyperthermia, Hypothermia, Windchill, CantSprint, Uncomfortable, NoxiousSmell, FoodEaten). Matched the live column slot for slot.
- **Q200** `UIManager.updateMouseMove` walks the UI list from the top: the first visible element under the pointer gets `onConsumeMouseMove` (Lua `onMouseMove`'s return value); once one returns true, the elements below that are also under the pointer get NOTHING (not even onMouseMoveOutside). A transparent Lua panel above a Java element and returning true suppresses that element's hover.
- **Q201** `UIManager.setShowLuaDebuggerOnError(false)` turns off the Lua debugger's break-on-error (the debug toolbar's tick box; -debug ticks it on every launch). The QA bridge now does this when it arms.
- **Q202** God mode resets needs every tick: `stats:set(CharacterStat.HUNGER, x)` reads back 0 a second later. QA that needs moodles: `player:setGodMod(false)`, then restore it.
- **Q203** `ISUIHandler.allUIVisible` flips only in `ISUIHandler.toggleUI()` (the Toggle UI key); `ISUIHandler.setVisibleAllUI(v)` hides / restores the UIManager list without touching the flag.
- **Q204** Main menu, Lua: `Events.OnMainMenuEnter` and `Events.OnFETick` (front-end ticks) fire there; `MainScreen.onMenuItemMouseDownMainMenu(MainScreen.instance.latestSaveOption, 0, 0)` continues the latest save.

**Q205–Q210 (Oct 14 2026, the main menu on 42.21.0).**

- **Q205** Texture filtering is a per-texture flag fixed at its FIRST load (cached by path for the session): `getTexture(path)` loads a mod texture LINEAR (pixel art drawn at 4x blurs); `Texture.getSharedTexture(path, 3)` loads it nearest (`TextureFlags.FILTER_MIN_NEAREST` 1 + `FILTER_MAG_NEAREST` 2). `useTextureFiltering(false)` did not make a mod texture nearest. `TextureID` (`tex:getTextureId()`) is not exposed, so its `setMagFilter` cannot be called. A PNG added while the game runs is not found until a restart (the file index is built at boot).
- **Q206** Kahlua compiler bug: in a `return`, `A and B and ((C and t) or (D and t)) and true or false` can return the table `t` instead of `true` (reproduced: same expression, one input gives a table, the other a boolean). Write explicit `if` / `return true`. (Separately, plain Lua: `cond and nil or x` always yields `x`.)
- **Q207** `getCore():TakeFullScreenshot(name)` grabs the frame already drawn (a change made in the same Lua call is not in it) and saves RGBA with the framebuffer's alpha: translucent UI areas look lighter in an image viewer than on screen; read RGB to judge. The capture stalls rendering for a moment.
- **Q208** In game, `Events.OnTick` stops while the pause menu is open (game speed 0); `Events.OnRenderTick` keeps running. The QA bridge now polls on OnRenderTick in game, OnFETick at the main menu.
- **Q209** Vanilla's `ToggleEscapeMenu` calls `MainScreen.instance:onEnterFromGame()` each time the pause menu opens, which calls `onEnterFromGame()` on every child that has it (and `onReturnToGame()` on close): the clean place to reset a pause panel. Sub-screens (Options, Players...) hide `MainScreen.bottomPanel`; it shows again when they close, so `bottomPanel:isVisible()` = "the menu itself is up" both at the main menu and in game. In game (42.21.0) vanilla's prerender also draws the logo over the paused world.
- **Q210** Save info: `getFullSaveDirectoryTable()` keys are `Mode\folder` (file separator), the same key `getSaveInfo(key)` and `getTextureFromSaveDir("thumb.png", key)` take; `MainScreen.latestSaveGameMode .. getFileSeparator() .. MainScreen.latestSaveWorld` builds it. `getSaveInfo` gives `saveName`, `gameMode`, `mapName` (every town of the county joined by `;` for a Knox Country save), `playerAlive`, `players` (`{ name, isDead, sqlID }`), `activeMods`, `worldVersion`, `lastPlayed` ("14/10/2026 20:05"); `getLastPlayedDate(key)` returns "Last played:14/10/2026 20:05". `getCore():getVersion()` is "42.21.0 4a0e9546ec". The mod blanks vanilla's `media/ui/Title*.png` (1x1, since v0.1), so `getTexture("media/ui/Title.png")` returns the blank: the engine's painting never shows behind vanilla's screens (42 draws its newer illustrated scene there instead).
- **Q211** Kahlua `string.gsub` with a FUNCTION replacement (`s:gsub("(%a)([%w']*)", function(a, b) ... end)`) broke at runtime inside a UI prerender (stack shows the pattern as the function name, and later draw calls fail with nil arguments). Use a plain character loop; string replacements are fine.
- **Q212** A focused `ISTextEntryBox` takes Return itself and calls its `onCommandEntered(self)`; once the field lets go of focus in that callback, the SAME key also reaches `Events.OnKeyPressed` (so a menu's Return handler fires too: saving a preset also pressed ACCEPT, a rename would have pressed PLAY). Swallow Return for ~400 ms after `onCommandEntered`.
- **Q213** Vanilla Options as an engine: `MainScreen.instance.mainOptions` builds every page in `create()` even while hidden; `mo.tabs.viewList` = `{ name, view }` per page; every option is `mo.gameOptions.options[i]` = `{ name, control, toUI, apply, onChange? }`. Emulate a user change the way the control would: combo `c.selected = i; c.onChange(c.target, c, c.onChangeArgs[1], c.onChangeArgs[2])`; tick box `c.selected[i] = v; c.changeOptionMethod(c.changeOptionTarget, i, v, c.changeOptionArg1, c.changeOptionArg2, c)`; volume `c:setVolume(v)`; slider `c:setCurrentValue(v)`; colour button `c.backgroundColor = {...}; mo.gameOptions:onChange(opt)`. Then `mo:apply(closeAfter)` keeps every rule (monitor revert, restart, DelayResetLua, PZAPI.ModOptions save). Labels pair with controls by row (same y, label right edge left of the control); section titles are `UIFont.Medium` labels. Key binds live in `MainOptions.keyText` (`txt:getName()` = id, `.translation` = text, `keyCode/shift/ctrl/alt`, `btn`); a capture is a top-level element with `setWantKeyEvents(true)` + `setWantExtraMouseEvents(true)` (`onKeyRelease`, `onMouseButtonDown(btn)` -> `Mouse.BTN_OFFSET + btn`, `isKeyConsumed` true) and `GameKeyboard.setDoLuaKeyPressed(false)` while it listens.

**Q214–Q216 (Oct 15 2026, map / spawn on 42.21.0).**

- **Q214** Vanilla `MapSpawnSelect` as an engine: `fillList()` fills `listbox.items[i].item` = `{ name, region, dir, desc, zoomX, zoomY, zoomS, demoVideo }` (towns filtered by `only_for_game_mode`, sorted by `MapsOrder`, `IgnoredMap` dropped); `region.points` = spawn houses per profession (`{ posX, posY, posZ }`, absolute squares; old mods give `worldX/worldY` cells). `clickNext()` reads `listbox.selected`, `textEntry` (save name) and `seedTextBox`, then shows sandbox options (Sandbox without `map_sand.bin`) or character creation; `clickBack()` follows `previousScreen` (NewGameScreen / LoadGameScreen / WorldSelect / LastStandPlayerSelect). Its "Random" row never appears in 42.21 (fillList tests `#listbox.items > 1` before adding any town). Its map panel (`MapSpawnSelectImage`, a Java `UIWorldMap`) can live in another panel: `other:addChild(mp)` detaches it, `setmetatable(mp, Derived)` replaces its prerender (vanilla's reads `self.parent.listbox`); `fillList` keeps clearing and reloading the same panel wherever it sits.
- **Q215** `UIWorldMap` (`mp.mapAPI` = `getAPIv3()`, non-isometric): `getWorldScale()` = UI pixels per square = k * 2^`getZoomF()` (one zoom step doubles it); `worldToUIX/Y(wx, wy)` and `uiToWorldX/Y(x, y[, zoomF, cx, cy])` work in the element's own pixels; `centerOn`, `setZoom`, `transitionTo(x, y, zoom)` glides; `zoomAt(x, y, del)` moves 0.5 zoom per wheel notch; `resetView()` fits the data bounds. Data loads asynchronously: style and view only once `getDataCount() > 0 and isDataLoaded()`.
- **Q216** `sanitizeWorldName(s)` turns spaces into `_` and keeps `- _ . , ' ( ) ! & #`; vanilla refuses a save name that sanitizes differently, so "My Run" is refused with only a red box. `getVideo(file, w, h)` (e.g. `"Riverside.bik", 1920, 1080`) returns a cached `VideoTexture`; call `:RenderFrame()` every frame before drawing it; when `getCore():getOptionDoVideoEffects()` is off vanilla shows `media/videos/<file>.png` instead (not every video has one).

**Q217–Q218 (Oct 15 2026, sandbox options on 42.21.0).**

- **Q217** A focused `ISTextEntryBox` keeps Escape (and Tab) to itself: the key never reaches `MainScreen:onKeyRelease`, and the field stays focused. It calls `entry.onOtherKey(entry, key)` instead (vanilla's chat and teleport UIs use it); Return goes to `onCommandEntered` (and then on to the menu, Q212). `entry:selectAll()` selects the text so typing replaces it.
- **Q218** Vanilla `SandboxOptionsScreen` as an engine (`MainScreen.instance.sandOptions`, built in `create()`): pages = `listbox.items[i].item.page` (`{ name, settings }`; 42.21: Time, Zombie, Loot, World, Nature, Meta, Character, Vehicles, Livestock); every setting's control is `controls[setting.name]`: `checkbox` -> ISTickBox (`changeOptionMethod` = `onTickBoxSelected`, which syncs ZombieMigrate), `enum` -> ISComboBox (`onChange` = `onComboBoxSelected`, which syncs Zombie Count -> population and Zombie Respawn -> its three numbers), `entry` / `string` -> ISTextEntryBox, `entry` with `advancedCombo` -> `SandboxAdvancedControl` (`.combo` of named steps + Custom, `.entry` the number, `getText` / `setText`; its own `onComboBoxSelected` reaches `self.parent.parent.controls` and fails for a page vanilla never showed). Tooltips end with "Min: x Max: y Default: z"; `getSandboxOptions():getOptionByName(n)` has `getMin/getMax/isValidString`. Vanilla's prerender (only while visible) runs `syncStartDay()` (Start Day's days follow Start Month). Presets: `presets[i] = { name, options, userDefined }`, `presetList.selected`, `onPresetChange()` = `settingsToUI(preset.options)`; `loadPresets()` re-applies whichever preset is selected (a save or delete changes the values on screen); `settingsFromUI(options)` fills any `SandboxOptions.new()`. NEXT = `onOptionMouseDown({ internal = "PLAY" })` (setSandboxVars, the preset's name, character creation); BACK = `{ internal = "BACK" }` (map / spawn).
- **Q219** Vanilla `CharacterCreationProfession` as an engine (`MainScreen.instance.charCreationProfession`): `listboxProf.items[i].item` = `CharacterProfessionDefinition` (`getUIName`, `getCost` = points it gives, Custom Occupation +8; `getTexture` ~60x40, nil for Custom; `.tooltip` = description), choose with `listboxProf.selected = i; onSelectProf(def)` (swaps the granted free traits, drops excluded ones, sets `MainScreen.instance.desc`); `listboxTrait` / `listboxBadTrait` = traits still available (`CharacterTraitDefinition`: `getLabel`, `getCost` (+ good, - bad), `getRightLabel` "-4" / "+2", `getTexture` 16-18 px, `getDescription`, `isFree`); `addTrait(def)` and `removeTrait(index into listboxTraitSelected)` keep the exclusions and granted traits; `checkXPBoost()` fills `listboxXpBoost.items[i].item = { perk, level }` (Fitness / Strength start at 5); `PointToSpend()` includes the sandbox's free points and `negativeTraitOffset()`. Builds: `savedBuilds.options` are plain strings, `BCRC.readSaveFile/writeSaveFile` (`saved_builds.txt`, "name:prof;trait;..."), `CharacterCreationProfession.loadBuild(self, savedBuilds)` loads the selected one, `saveBuildStep2(button)` reads `button.parent.entry:getText()`, vanilla's delete loads another build afterwards. `randomizeTraits()`, `resetTraits()` (clears traits, keeps the occupation). NEXT = `onOptionMouseDown({ internal = "NEXT" })` -> `charCreationMain`; its BACK = `charCreationProfession:setVisible(true)`.
- **Q220** Vanilla `CharacterCreationMain` as an engine (`MainScreen.instance.charCreationMain`): its `setVisible(true)` itself dresses the character (`randomGenericOutfit()`: default + occupation + trait clothing) and `checkAllClothingOptions()`; a redirect that skips it must call both. Controls: `forenameEntry` / `surnameEntry` (read by `initPlayer` at PLAY; re-rolled by a sex change, RANDOM and outfit loads), `genderCombo` (`onGenderSelected`), `skinColors` (5) + `colorPickerSkin.index` then `onSkinColorPicked(color, true)`, `chestHairTickBox` / `hairStubbleTickBox` / `beardStubbleTickBox` (male-only rows hidden by `disableBtn`), `hairTypeCombo`, hair colours = `desc:getCommonHairColor()` desaturated through `ColorInfo` (20) then `onHairColorPicked(color, true)`, `beardTypeCombo`, `voiceTypeCombo`, `voicePitchSlider` (ISSliderPanel -100..100), `voiceDemoButton`; clothing per body location id ("Hat", "Tshirt", "Pants", ...): `clothingCombo[loc]` (data = item full type; `onChange` = `onClothingComboSelected(combo, loc)`), `clothingColorBtn[loc]` (shown only for tintable items; `onClothingColorPicked({ r, g, b }, true, loc)`), `clothingTextureCombo[loc]` ("Type N", shown only with more than one), labels in `clothingComboLabel[loc]`. The 3D figure is `avatarPanel.avatarPanel` (ISUI3DModel: `getDirection():RotLeft()/RotRight()`, `setDirection`, `setState(nil)` + `reportEvent("EventWalk")`); it can be moved into another panel with `addChild` and vanilla's `setSurvivorDesc` calls still reach it. Saved outfits: `savedBuilds.options` strings, `readSavedOutfitFile` / `writeSaveFile` (`VERSION=1` header), `v:loadOutfit(savedBuilds)`, `saveBuildStep2(button)` reads `button.parent.entry:getText()`. PLAY = `onOptionMouseDown({ internal = "NEXT" })` (initPlayer, createWorld, LoadingQueueState); BACK = `charCreationProfession:setVisible(true)`. Starting a game writes `latestSave.ini` (save name, mode).

**Q221–Q223 (Oct 15 2026, join a server on 42.21.0).**

- **Q221** Kahlua has no `next` (it is nil): `next(t) ~= nil` throws "Object tried to call nil". Test a table with `for _ in pairs(t) do return true end`. (`select` and `unpack` exist.)
- **Q222** A window's children draw between its `prerender` and its `render`: anything painted in `render` covers them. A text field placed over a strip whose background is painted in `render` is invisible (still focused and typing). Paint backgrounds under children in `prerender`.
- **Q223** Vanilla multiplayer as an engine: `MainScreen.instance.multiplayer` (MultiplayerUI) keeps `accountList.items[i].item` = `{ type = "server" | "account" | "new_account" | "new_server", server, account }` (rebuilt by `refreshList()` from `getServerList()`), the public list in `internetList.items` (Server objects; Java filters and sorts them in `sortBrowserList` when `updateListSort()` runs, which vanilla only calls while its screen renders), `selectedInternetServer`, `getServerFeatured(server)`, `onSelectInternetServer(server)` (asks Steam for details and rules), `requestServerList()` (refuses again within 60 s, 5 s in debug; `MultiplayerUI.startRefreshTime`), the filter tick boxes (`filterVersion`, `filterEmptyServer`, `filterFullServer`, `filterPwdProtected`, `filterWhitelistServer`, `filterModdedServer`, the `filter` text) and `onClickSort({ internal = "name" | "player" | "ping" })`. Saving: `addServerToAccountList`, `updateServerToAccountList`, `deleteServerToAccountList`, `addAccountToAccountList(server, account)`, `updateAccountToAccountList`, `deleteAccountToAccountList`; `Server.new()`, `Account.new()` (`encryptPwd`, `setSavePwd`, `setAuthType(1)`: 42.21 offers only password sign-in). `connectToServer(server, account)` connects when the password is saved; otherwise vanilla opened ISMPEnterPassword, whose CONNECT calls `ConnectToServer.instance:connect(..., doHash = true, ...)` with the typed password. `ConnectToServer` follows the connection (OnConnectFailed, OnConnectionStateChanged) only while `getIsVisible()`, so a replacement must keep it shown (off the screen) and read `serverName`, `userName`, `connectLabel.name`, `connecting`, `googleAuthPopup`, `backBtn`; `onBackButton()` aborts or goes back. A server that has not answered reads `isOpen()` false and `isPasswordProtected()` false. The main menu's item handler (`onMenuItemMouseDownMainMenu`) hides the bottom panel at its very end, after the item's screen has shown.


**Q224–Q228 (Oct 15 2026, server settings on 42.21.0).**

- **Q224** `ServerSettingsScreen` (`MainScreen.instance.serverSettingsScreen`, also `ServerSettingsScreen.instance`) is eight child pages that flip their own visibility even while the screen is hidden: `pageStart` (Page1, the settings list: `listbox.items[i].item` is a ServerSettings), `pageNew` (Page2), `pageEdit` (Page3), `pageEdit.chooseModsWindow` (the mods step before editing), `pageDuplicate` (Page4), `pageRename` (Page5), `pageDelete` (Page6), `pageSpawnPoints` (Page7). Each page's `onButton*` methods do the work (`settings:duplicateFiles`, `rename`, `deleteFiles`, `saveFiles`, `saveSpawnPointsFile`). Every flip calls `setVisible(true, JoypadState.getMainMenuJoypad())`, and ISPanelJoypad's setVisible hands the controller to that page: a replacement must take it back (`jd.focus = MainScreen.instance; updateJoypadFocus(jd)`). `Page1:onButtonBack` shows `prevScreen` (the host screen) with aboutToShow + setVisible(true), or the menu's bottom panel.
- **Q225** `Page3`, `Page7` and `SettingsTable` are file locals in ServerSettingsScreen.lua (a global probe of any of them is nil; a module that indexes `Page3.ChooseModsWindow` at load fails to load). Reach their methods through the instances: `S.pageEdit.chooseModsWindow:onButtonNext()`, `pg.onRemoveProfession(pg.profListBox, i)`, `pg.onRemovePoint(pg.pointListBox, i)` (vanilla calls those two with the list box as self). Page3's own lists: `listbox.items[i].item` is `{ category = {name = "INI" | "Sandbox"} }` or `{ page, panel }`; values live in `controls[category][settingName]` (ISTickBox, ISComboBox, ISTextEntryBox; WaterShut and ElecShut have no control); special pages are `customui` panels (ModsPanel, MapsPanel, SpawnRegionsPanel, WorkshopPanel, SandboxPresetPanel) whose `parent` is set only while vanilla shows them (`pe:onMouseDownListBox(item)`). The INI pages' names are the INI keys. Group boxes exist in the code but no 42.21 page uses one.
- **Q226** The mods step's NEXT reloads every Lua file (`getCore():ResetLua("serversettings", "ServerSettingsChange=<name>")`) whenever `ActiveMods.requiresResetLua(serversettings)` says the server's mods differ from the loaded ones; SAVE and CANCEL reload back to "default" the same way. A UI mod that is not in the server's list is gone for the whole edit, and a NEW settings whose mods differ loses itself (it was never saved, so the reload lands on the list). `ActiveMods.requiresResetLua` is a Java static that Lua can replace for a call and put back. `getActivatedMods()` lists the loaded mod IDs. Vanilla's default mods for new settings are the active Workshop mods only (a local mod is never added).
- **Q227** 42.21 occupations are registry objects: `CharacterProfessionDefinition.getCharacterProfessionDefinition(p)` wants a `CharacterProfession` (`CharacterProfession.get(ResourceLocation.of("base:chef"))`), and `getType()` returns the namespaced ID ("base:unemployed"; its label is "Custom Occupation"). Vanilla's Page7 still passes the plain name, so its add and its loading of a region file that already has occupations both throw; its save rule wants a literal "unemployed". Spawn point files key the game's occupations by plain name (`unemployed = {...}`, as the maps' own files). Java exceptions inside `pcall` are still printed to the console, so a per-frame pcall of a throwing call floods the log: look up once and keep the answer.
- **Q228** `ServerSettingsManager:isValidNewName` and `ServerSettings:isValid` accept names with `/ \ : * ? " < > |` (the files then land in a subfolder or fail). The files a name makes: `getNameInSettingsFolder(name) .. suffix` for each of `getSuffixes()` (".ini", "_SandboxVars.lua", "_spawnpoints.lua", "_spawnregions.lua", "_zombies.ini"); `serverFileExists(name .. suffix)` tells which exist. A spawn region's own file is written as `serverfile = "x_spawnpoints.lua"` in the regions file and saved under `Zomboid/Server/`; vanilla only lets a region's points be edited when its file is a plain name ending "spawnpoints.lua".

**Q229 (Oct 15 2026, the game loading screen on 42.21.0).** Single player goes `forceChangeState(LoadingQueueState.new())` (MainScreen, CharacterCreationMain), and LoadingQueueState hands straight to `GameLoadingState` outside multiplayer. `GameLoadingState.render` is all Java: a full-screen black quad (no texture), the walking-zombie indicator (`AnimatedTextures.getTexture("media/ui/Progress/MaleWalk2.png")`, `MaleSprint06.png` when zombies sprint, `MaleDoor.png` while converting a world; drawn 196 px wide at the bottom centre, 0.66 alpha), "Loading..." with dots, the quick tips (`UI_quick_tip*` / `UI_quick_tip_joke*` translations), a new game's `UI_Intro1-3`, then `UI_ClickToSkip` / `UI_PressAToStart`. `UIManager.render` (the Lua UI) runs there only on the error branches (unexpected error, disconnect, wrong IP); `UIManager.suspend` is set while the loader thread works, and Lua is called only through `ISGameLoadingUI_OnGameLoadingUI` on those errors. So no Lua mod can draw a background or anything else over the loading screen. A mod can replace the indicator's PNGs (by path) and the texts (translation keys). The multiplayer login queue (LoadingQueueState with `placeInQueue`) does draw `MainScreenState.renderBackground` and the Lua UI. (Java mods are off the table: distributing changed classes.)

**Q230–Q233 (Oct 15 2026, the click audit on 42.21.0, 4K).**

- **Q230** Vanilla's pause mod list (`ISPauseModListUI`) marks a mod "[ERRORS]" from `PauseBuggedModList[modName]`, which the engine fills in `LuaClosure$DebugInfo.generateModName`: whenever a Lua stack trace element is built for one of the mod's closures (`toStackTraceElement`). Vanilla's own warnings build those (`DebugType.Lua:warn` reports its Lua caller), so a vanilla warning raised while a mod's hook is on the call stack flags that mod, with no error in the mod at all. 42.21: `CoopOptionsScreen:create` (run inside `MainScreen:instantiate`) asks `namedColorToTable("ProgressYellow")`, a colour 42.21 does not have, and warns; ZeD's instantiate hook was on the stack, so ZeD UI read "[ERRORS]" every session. ZeD answers that one colour quietly (`Overrides/MainMenu.lua`; the wrapper tail-calls vanilla's for any other name). Finding such a trigger: wrap every global function from a shared file named to load first and report the first call after which the flag is set.
- **Q231** `ZeD_Window` cached its close box rect in `createChildren`; a window built before the root scale settled (the main menu's windows at 4K) kept a 1x box in the corner of a 1.5x/2x title bar (drawn and clicked there). It is now worked out from the live tokens every frame (`ZeD_Window:closeRect()`).
- **Q232** Vanilla's controller options (`GameOptionControllerTab`) is not a UI element: it builds panels and keeps its parts as fields (`btnJoypadSensitivityM` / `P`, `labelJoypadSensitivity`, `controllerTestPanel`). Reach it through a collected button's `target`. The deadzone buttons stay off until a controller is picked in the test panel's combo (`ISControllerTestPanel:onControllerSelected`, which also sets `JoypadState.controllerTest`; picking `<None>` clears it). Its value label reads `getControllerDeadZone(controller, 0)` right after setting the axes, before the engine applies them, so it shows the value one press behind; read it live when drawing.
- **Q233** The engine's font size option: `getOptionFontSize()` 1-6 = 16px, 19px, 26px, 33px, 38px, "Scale with window height"; `getOptionFontSizeReal()` resolves 6 from the screen height (2160p -> 5, the 38px tier; 1080p -> 2, 19px) and picks the font folder. Engine-drawn text (the loading screen, the Java item tooltip) uses those fonts; ZeD's `media/fonts/EN/fonts.txt` maps the vanilla slots the loading screen uses (NewSmall, NewMedium, NewLarge, Small) to ZeD's role bitmaps, so the loading text is ZeD's face at the option's size. ZeD's own UI scales by its root scale, not by this option (`ZeD.Scale.USER_MUL` keeps "Scale with window height" neutral).

**Q234–Q235 (Oct 15 2026, maps on 42.21.0).**

- **Q234** The fog of war on a `UIWorldMap` is the renderer boolean **"HideUnvisited"** (default off; vanilla's in-game `ISWorldMap:initDataAndStyle` turns it on, the mini map too). A misspelt name ("HideUnvisitedAreas") is ignored silently and the whole map shows. With it on, `WorldMapVisited` (`setKnownInSquares` / `setVisitedInSquares`, filled by walking and by reading maps; all known under the sandbox's Map.MapAllKnown) masks every layer, image pyramids included: known ground draws dimmer than visited ground.
- **Q235** The spawn screen's illustrated county map is the base map's `spawnSelectImagePyramid.zip` (`getMapInfo("Muldraugh, KY").spawnSelectImagePyramid`, a full path), laid out in world squares (19801 x 16086). `MapSpawnSelectImage` shows it on a map with no data and no style (`addImagePyramid` + `setBoolean("ImagePyramid", true)`). On a map that also has data, the style's layers and the other pyramids (`pyramid.zip` terrain, `forest.pyramid.zip`) draw over it; one `UIWorldMap` can switch between the two by `getStyleAPI():clear()`, `clearImages()`, `clearData()` and loading the other set (`MapUtils.initDefaultMapData` + `initDefaultStreetData` + `initDefaultStyleV3` + `overlayPaper` for vanilla's in-game look). Past zoom ~16 the illustration is only enlarged.

**Q236–Q240 (Oct 15 2026, vanilla's pop-ups as ZeD prompts on 42.21.0).**

- **Q236** `ZeD_Window:prerender` sets `self.minimumWidth / minimumHeight` to the big windows' minimum (`T.minWinW / minWinH`, 540 x 330 at 1.5x) every frame, and `ISUIElement:onResize` (the engine calls it on every resize) holds an element to its minimum with `setWidthOnly / setHeightOnly`, without going through Lua's `setWidth`. A small window derived from `ZeD_Window` (the prompt, the keyboard) must zero both after `ZeD_Window.prerender` and in `createChildren`. Symptom: the window grows to the minimum, and any "keep the centre" placement walks it across the screen a few pixels a frame.
- **Q237** A text field keeps the keyboard after its panel is removed from the UI manager (`ISTextEntryBox:isFocused()` stays true): Enter and Escape still reach its `onCommandEntered` / `onOtherKey`, and no `OnKeyPressed` fires for anything else while it holds the keys. Unfocus a panel's fields when it closes (`ZeD_Prompt` releaseFields), and let a closed dialog answer only once.
- **Q238** `onMouseWheel(del)`: a positive `del` is the wheel turned down, towards the player (vanilla's lists do `setYScroll(getYScroll() - del * n)`). Scroll down / step a value down on `del > 0`.
- **Q239** Escape's pause menu is `ToggleEscapeMenu`, registered once in MainScreen.lua with `Events.OnKeyPressed.Add(ToggleEscapeMenu)`; replacing the global later does not change the registered handler. To let something answer Escape first, `Events.OnKeyPressed.Remove(ToggleEscapeMenu)` and add a handler that calls the global when it does not take the key (`Overrides/Prompts.lua`). It also calls `MainScreen.instance:onKeyRelease(key)` at its end, so a key taken before it never reaches the main menu either.
- **Q240** Vanilla's dialog classes as a contract (what callers rely on): `ISModalDialog:new / ISModalRichText:new / ISTextBox:new` place the dialog on the pointer when x / y are 0 (centred on the player's screen when that player is on a controller), else in the caller's box; callers then set fields on the dialog (`modal.animal`, `.playerObj`, `.ui`, `.prevFocus`, `.moveWithMouse`, `.maxChars`, `.noEmpty`, `.backgroundColor.a`) and call `setAlwaysOnTop`, `bringToTop`, `setCapture`, `centerOnScreen`, `ignoreHeightChange`, `chatText:paginate()` + `setHeightToContents()` (the window info "?"), `modal.no:forceClick()`. Answers read `button.internal` ("YES" / "NO" / "OK" / "CANCEL"), `button.parent.<field>` and `button.parent.entry:getText()`; ISModalDialog sets `button.player` first. `destroy` differs per class: ISModalDialog and ISModalRichText (always) reset the game speed to 1 (the survival guide pauses and its closing note unpauses), ISTextBox calls back before it closes (and stays open while `showError` is set), ISAlarmClockDialog closes when the character steps (B presses Ok), ISBombTimerDialog keeps the IsoPlayer in `.player` and the index in `.playerNum` (`button.parent:getTime()`, minimum 1). Subclasses build through the parent (`ISModalDialog.new(self, ...)`), so a replacement must act only when called on the class itself. The controller keyboard is `OnScreenKeyboard` (Show / IsVisible / Hide / GetCurrentText on `.instance`); a text field keeps its caret while focus is on an element whose `Type` is "ISOnScreenKeyboard", and the keyboard types with `queueCharEvent` / `queueKeyEvent` into whatever field holds the keys.

**Q241–Q243 (Oct 15 2026, the radial wheels on 42.21.0).**

- **Q241** Vanilla's radial menus are two Lua objects over the Java `zombie.ui.RadialMenu` (final): `getPlayerRadialMenu(id)` (one `ISRadialMenu` per player, shared by every wheel: vehicle, animal, emotes, firearm, light, map, the D-pad wheels, left stick, furniture, hotbar, mods) and the controller's `ISBackButtonWheel` (derives it, kept in `ISPlayerDataObject.backButtonWheel`). The engine draws everything and never calls the Lua `prerender` / `render` / `update`. Geometry (from the bytecode): slice 1 centred at 12 o'clock, clockwise, `360 / max(n, 2)` degrees each (one slice draws as the top half), a slice with nil text and nil texture is an empty place (kept, never picked); the mouse picks by `atan2(dy, dx) + 180` outside the inner radius (100) and inside the outer (200), and picks on the press; a controller picks by the aiming stick (`getJoypadAimingAxisX / Y(id)`, -1 when not pushed) when the button set by `setHideWhenButtonReleased` is let go; B / X close. Slices added with a nil command are information ("No key...", "Not tired enough to sleep.") that look like any other. No Lua outside `ISRadialMenu.lua` touches the Java object, so replacing `instantiate` (a plain `UIElement`) and keeping the slices in Lua replaces every wheel at once.
- **Q242** `Texture:getName()` is the bare name for a packed texture ("vehicle_horn", "trait_talkative") but the full Windows path with backslashes for a file texture ("E:\...\media\ui\emotes\back.png"). Normalise (`gsub("\\", "/")`) before matching path patterns.
- **Q243** `ISUIElement:instantiate` passes `setConsumeMouseEvents(self.wantMouseEvents or false)`: a Lua-drawn element standing in for an engine one that took its clicks (the radial) sets `wantMouseEvents = true` first. The vanilla windows the wheels open have shared entry points every path uses: `ISSearchWindow.toggleWindow(character)` (the Back wheel, the screen icons), `ISDesignationZonePanel.toggleZoneUI(playerNum)` (D-pad Right, the screen icons), `getPlayerInfoPanel(n)` (the Back wheel's Player Info, through `ISBackButtonWheel.onCommand("PlayerInfo")`).
