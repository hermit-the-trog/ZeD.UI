# Community UI Mod Architecture — Competitive Intelligence

Extracted patterns from the most successful PZ Build 42 UI mods. Two dominant authors: **Rocco** (NeatUI ecosystem: CleanUI, Neat Crafting, Modern Status, Neat Building, Project Cook, Clean HotBar — 6+ interconnected mods on shared framework) and **Notloc** (Inventory Tetris, Equipment UI, Reorder tools — monkey-patching with data-driven sizing).

Nobody has built a unified Character Window that replaces ISCharacterScreen entirely. That gap is ours.

---

## Table of Contents

1. Five Replacement Patterns
2. Inventory Mods — Architecture & Tricks
3. Character Info & Health — Overlays & Body Visualization
4. Crafting UI — Recipe Systems & Filtering
5. HUD & Moodles — Status Reading & Display
6. Actionable Patterns for Character Window & World Window
7. Java API Reference for Character/World Tabs
8. Compatibility & Resilience Lessons

---

## 1. Five Replacement Patterns

Every PZ UI mod falls into one of five architectural patterns:

### Full File Replacement
Place mod file at same path as vanilla, completely overwriting. Used by: Inventory Tetris, CleanUI, Inventory ReInvented, Reorganized Info Screen.
- **Pro:** Total control, clean implementation
- **Con:** Extremely fragile to game updates; two mods replacing same file = irreconcilable conflict
- **ZeD approach:** We use this for ISInventoryPage (naming our class `ISInventoryPage` via derive to satisfy Java API contract) but build from scratch rather than copying vanilla

### Derive-and-Override
Save reference to original function, wrap or replace specific methods. Used by: Inventory Matrix, Bigger Character Avatar.
```lua
local original_createChildren = ISCharacterInfo.createChildren
function ISCharacterInfo:createChildren()
    original_createChildren(self)
    self.avatarPanel:setWidth(300)
end
```
- **Pro:** Preserves vanilla behavior you don't touch
- **Con:** Tied to parent class data model and lifecycle

### Standalone Overlay
New UI panels that read game state independently. Used by: Equipment UI (Paper Doll), Mini Health Panel, Modern Status.
- **Pro:** Maximum compatibility — nothing vanilla modified
- **Con:** UX fragmentation (two parallel interfaces)
- **ZeD relevance:** Our moodle bar and watch are standalone overlays

### Tab Injection
Add tabs to existing ISCharacterScreen. Used by: KillCount, Armor Makes Sense.
```lua
local orig = ISCharacterScreen.createChildren
function ISCharacterScreen:createChildren()
    orig(self)
    local myPanel = MyCustomPanel:new(0, 0, 200, 200)
    myPanel:initialise()
    self:addPage("My Tab", myPanel)
end
```
- **Pro:** Cleanest extension, no conflicts
- **Con:** Stuck inside vanilla window chrome

### Framework/Plugin
Extensible API other mods consume. Used by: NeatUI Framework, Inspect Items Framework.
```lua
-- Inspect Items Framework pattern
ItemInspection.RegisterPlugin({
    category = "Weapon",
    getStats = function(item) return {...} end,
})
```
- **Pro:** Most architecturally sophisticated, future-proof
- **Con:** Requires adoption by other mod authors
- **ZeD relevance:** We should expose `ZeD.RegisterTab(windowType, tabDef)` for third-party tab injection

---

## 2. Inventory Mods — Architecture & Tricks

### Inventory Tetris (Notloc) — 110,000+ collections
**Open source:** GitHub `Notloc/zomboid-inventory-tetris`, 322 commits, 100% Lua.

Architecture:
- `ItemGrid.lua` (~900 lines) — 2D spatial grid, items occupy width×height cells
- `TetrisItemData.lua` — item size resolution via fallback chain: JSON cache → Lua data pack overrides → weight/type formula (any modded item auto-works)
- `ItemGridUI_rendering.lua` — all draw calls separated from logic
- `ItemGridUI_events.lua` — all input handling separated from rendering
- Grid state persists via PZ `moddata` system (Java GlobalModData)

Key tricks:
- **Render/event separation** — rendering and input in separate files for maintainability
- **Data-driven auto-sizing** — fallback chain means zero compatibility patches needed
- **Cached item data** — `InventoryTetris_ContainerData.json` and `InventoryTetris_ItemData.json` in `Zomboid/Lua/`
- **Event-driven grid updates** — `refreshContainer` hooks, not polling

MP challenge: Clients auto-position items and send moddata with newer timestamps, overwriting server state. Needs per-item timestamps.

### CleanUI (Rocco) — 89,000 collections
Built on NeatUI Framework shared library. Delegates text measuring, truncation, and rendering to NeatUI centralized helpers.

Key tricks:
- **Shared framework dependency** — actual inventory replacement is thinner because NeatUI handles primitives
- **Selective vanilla delegation** — fully replaces `ISInventoryPane.lua` but delegates context menu to vanilla's `ISInventoryPaneContextMenu.lua` (avoids reimplementing the massive context menu system)
- **Transfer-by-category** — batch transfer items filtered by type

### Inventory ReInvented — 17,000 subscribers
Replaces ISInventoryPane, ISInventoryPage, AND ISPlayerDataObject.

Key tricks:
- **ISPlayerDataObject.createInventoryInterface** — the canonical interception point for replacing inventory creation
- **Drowsy blur effect** — reads `player:getStats():getFatigue()`, applies proportional texture blurring to item icons
- **Blood-on-icons** — reads body damage state, renders blood overlay on character icons

### Inventory Matrix — 4,200 subscribers
Derive-and-override only. Preserves vanilla container management, sorting, and context menus.

Key tricks:
- **Dynamic column fitting** — adjusts columns based on window width
- **Inherently compatible** — works with Nested Containers and Reorder Containers out of the box because it only touches rendering

### Nested Containers
Pure hook-and-modify. Only extends container discovery in `ISInventoryPage.refreshBackpacks()`.

Key trick:
- **Scan for containers inside containers** — surfaces them as additional selectable tabs. No new UI classes.

---

## 3. Character Info & Health — Overlays & Body Visualization

### Critical Gap: No comprehensive ISCharacterScreen replacement exists
The community has opted for targeted overlays and tab injections rather than full replacement. This is the space ZeD fills.

### Reorganized Info Screen (soulfilcher) — 32,000 subscribers
Closest to full ISCharacterInfo replacement. Full file replacement approach.

Lessons:
- **Currently broken on B42.13+** — illustrates fragility of full file replacement
- **Known conflicts** with KillCount (both modify ISCharacterScreen), Profession Backgrounds, Spongie's Character Customisation
- Enlarges ISUI3DModel viewport, fixes stat retrieval bugs for age/survivor kills
- Reads correctly from `IsoPlayer` Java object where vanilla had errors

### Equipment UI — Paper Doll (Notloc) — In virtually every B42 mod collection
Standalone overlay with 2D STALKER/Tarkov-style body silhouette.

Architecture:
- ISPanel-based window
- Each slot is an **ISButton derivative** tracking `BodyLocation`
- Renders equipped item textures via `drawTextureScaled`
- Right-click context menus for equip/unequip
- Reads from vanilla `BodyLocation` system, maps slots to visual positions
- Layout persists between sessions

**Directly reusable pattern for Equipment tab.**

### Mini Health Panel (Lore)
Standalone overlay, companion pattern. Custom 2D body figure (NOT ISUI3DModel).

Key code pattern — wound state polling:
```lua
function MiniHealthPanel:prerender()
    ISPanel.prerender(self)
    local bd = player:getBodyDamage()
    local bodyPart = bd:getBodyPart(BodyPartType.Hand_L)
    local scratched = bodyPart:scratched()
    local bleeding = bodyPart:bleeding()
    -- render colored indicators based on wound state
end
```

Features:
- Auto-hides when no wounds need treatment
- B42 muscle strain indicators (opacity/color from orange to red)
- **Polling-based wound reading is the standard approach**

### Inspect Items Framework (MasterGG) — 18,500 subscribers, B42.13+
Plugin API architecture:
- `ItemInspection.RegisterPlugin()` — mods add custom stat modules, override categories, add descriptions
- 3D preview: real-time rotation (hold RMB), zoom (mouse wheel), auto-rotation toggle
- 2D/3D toggle, adaptive scaling, Alt+double-click fullscreen
- **This plugin architecture is the model for extensible tab systems**

### Armor Makes Sense (Deharath) — MIT licensed, GitHub
Cleanest B42 tab injection:
- Overrides `ISCharacterScreen.createChildren` to inject "Burden" tab
- Auto-classifies items by defense stats and weight (no hardcoded item lists)
- Uses Starlit Library for tooltip integration
- **Has an in-game benchmark/testing harness** — unusual and valuable pattern

### Three approaches to body visualization:
1. **Vanilla ISUI3DModel** — full 3D rendered player model (Reorganized Info Screen, Bigger Character Avatar)
2. **Custom 2D body figures** — simplified outline with colored indicators (Mini Health Panel)
3. **Paper doll slots** — 2D body outline with ISButton-derived equipment slots (Equipment UI)

**ZeD approach:** ISUI3DModel for Equipment tab (with `setSurvivorDesc()` for preview), custom 2D body figure (absorbed from CharInfoOverhaul) for Health/Protection/Thermal overlays.

---

## 4. Crafting UI — Recipe Systems & Filtering

### Neat Crafting (Rocco) — B42 only, NeatUI ecosystem
Complete crafting panel replacement (NOT derived from ISCraftingUI).

Architecture:
- Built on NeatUI Framework utilities
- Registers `WorldDictionary` key (`NC_HandCraftPanelLayout`) — **removing mod from save causes WorldDictionaryException crash**
- Toggle between Neat Crafting and vanilla via Mod Options or right-click sidebar button

Key tricks:
- **Improved categorization** — compact category lists with hover-expanded names
- **Custom category icons** via `media/ui/CategoryIcon/` (base PSD template)
- **Smart input display** — shows only kept and partially consumed items, hides fully consumed
- **Lazy update** — crafting list updates only when needed, not every frame

### Craft Helper Continued (lanceris) — B41, MIT licensed
Context-menu-hook pattern:
```lua
local function onFillInventoryContext(player, context, items)
    for i, v in ipairs(items) do
        local item = v
        if hasRecipes(item) then
            context:addOption("Craft Helper", item, openCraftHelperUI)
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContext)
```
- Queries `getAllRecipes()` for recipes where items are ingredients
- `getScriptManager():getItemsTag()` for tag-based lookups
- Recursively right-clickable result icons for nested recipe lookup

### B42 Crafting API Constraint
**The `craftRecipe` system is significantly harder to mod than B41's Recipe system.** Adding items to existing recipe inputs requires accessing Java's cached `loadedItems` field through `testFunction` workarounds. Any crafting UI replacement must account for this restricted API.

---

## 5. HUD & Moodles — Status Reading & Display

### Modern Status (Rocco) — 1,945 ratings, B42
Definitive HUD replacement. Two visual styles (circular, bar), freely mixable per-indicator.

Player stats available (20+ confirmed):
```
Health, Hunger, Thirst, Fatigue, Boredom, Unhappiness, Stress, Pain,
Endurance, Sickness, Wetness, Body Temperature, Weight, Calories,
Protein, Fat, Carbohydrates, Fitness, Strength, Drunkenness,
Medication durations: Antibiotics, Painkillers, Sleeping Pills, Beta Blockers
```

Key tricks:
- **Double-click actions** per indicator (e.g., Thirst → drink safe liquid) — context-sensitive HUD interaction
- **Third-party mod integration** — Wash or Rot (Itchiness), LifeStyle (Hygiene), Bodily Functions
- **2-second cycling** for medication durations
- Config persists to `ModernStatusConfig.lua` in `Zomboid/Lua/`

### Moodle Framework (B41) — Developer API pattern
```lua
require "MF_ISMoodle"
MF.getMoodle("MyMoodle", playerNum):setValue(0.75)  -- float 0.0–1.0
```

### B42 Moodle Limitation
**Moodle tooltip rendering appears to be Java-side in Build 42, not Lua-accessible.** Moodle Descriptions Expanded author confirms tooltips are hard-coded differently in B42. Our moodle bar bypasses this entirely by rendering our own moodle display.

### Realistic Dashboard & Gauges
Overrides `ISVehicleDashboard.lua` entirely. Physics-based gauge needle motion, dynamic stain/crack effects.
- Reads speed: `self.vehicle:getCurrentSpeedKmHour()`
- Dynamic positioning: `self.doorTex:getX()` / `self.doorTex:getWidth()`
- **Common conflict point** — multiple mods override same file

---

## 6. Actionable Patterns for Character Window & World Window

### Interception Point
```lua
local original = ISPlayerDataObject.createInventoryInterface
function ISPlayerDataObject:createInventoryInterface()
    original(self)
    -- self.inventoryPage now exists, can be swapped
end
```

### Character Window Tab Architecture
Each tab = independent ISPanel subclass reading from different Java APIs:

| Tab | Data Source | Pattern Source |
|-----|-----------|---------------|
| Equipment | `BodyLocation` system, `drawTextureScaled` | Equipment UI |
| Health | `player:getBodyDamage():getBodyPart(BodyPartType.X)` | Mini Health Panel |
| Skills | `player:getXp()` | vanilla ISSkillProgressBar |
| Protection | Equipment iteration, `getBiteDefense()` etc. | Armor Makes Sense |
| Thermal | Body-part-level insulation calcs | ISClothingInsPanel |
| Journal | `player:getZombieKills()`, reading progress | vanilla ISCharacterInfo |
| Identity | `IsoPlayer` object, traits, profession | Reorganized Info Screen |

### World Window Context Detection
```lua
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    for _, obj in ipairs(worldObjects) do
        -- Check for stove, campfire, fishing spot, etc.
        -- Show/hide contextual tabs based on proximity
    end
end)
```

### Plugin API for Third-Party Tab Registration
```lua
ZeD = ZeD or {}
ZeD.RegisterTab = function(windowType, tabDef)
    -- windowType: "character" or "world"
    -- tabDef: { id, icon, label, panelClass, contextual, condition }
    local registry = ZeD._tabRegistry[windowType] or {}
    table.insert(registry, tabDef)
    ZeD._tabRegistry[windowType] = registry
end
```

---

## 7. Java API Reference for Character/World Tabs

### Body Damage (Health Tab)
```lua
local bd = player:getBodyDamage()
bd:getBodyPart(BodyPartType.Hand_L)  -- returns BodyPartType
bodyPart:scratched()      -- boolean
bodyPart:bleeding()       -- boolean
bodyPart:bitten()         -- boolean
bodyPart:deepWounded()    -- boolean
bodyPart:getBurnTime()    -- float
bodyPart:getFractureTime() -- float
bodyPart:getStiffness()   -- float (B42 muscle strain)
```

### Player Stats (Moodle Bar)
```lua
local stats = player:getStats()
stats:getHunger()         stats:getThirst()
stats:getFatigue()        stats:getStress()
stats:getPain()           stats:getBoredom()
stats:getUnhappiness()    stats:getEndurance()
stats:getSickness()       stats:getDrunkenness()
player:getBodyDamage():getWetness()
player:getBodyDamage():getTemperature()
player:getNutrition():getCalories()
player:getNutrition():getProteins()
player:getNutrition():getCarbohydrates()
player:getNutrition():getLipids()
player:getNutrition():getWeight()
```

### XP System (Skills Tab)
```lua
local xp = player:getXp()
xp:getXP(Perks.Fitness)       -- current XP
xp:getXPForLevel(level)       -- XP required for level
player:getPerkLevel(Perks.Fitness) -- current level
```

### Clothing Defense (Protection Tab)
```lua
-- Iterate equipped items
local wornItems = player:getWornItems()
for i = 0, wornItems:size() - 1 do
    local item = wornItems:getItemByIndex(i)
    item:getBiteDefense()
    item:getScratchDefense()
    item:getBodyLocation()
end
```

### Vehicle (World Window Context)
```lua
self.vehicle:getCurrentSpeedKmHour()
self.vehicle:getEngineSpeed()
self.vehicle:getBatteryCharge()
```

---

## 8. Compatibility & Resilience Lessons

### FWolfe's Golden Rule
"Always overwrite as little as possible to achieve your goal. Don't replace a whole file if you can do it by overwriting a single function."

### API Surface Minimization
Build 42 update cadence (B42.12 → B42.13 broke MP, B42.15 broke more) means fewer vanilla function overrides = fewer breakage points per update.

### Context Menu Delegation
CleanUI's smartest decision: fully replace ISInventoryPane but delegate context menu creation to vanilla's ISInventoryPaneContextMenu. Avoids reimplementing the massive context menu system and preserves all mod-injected context actions.

**B42.16 update**: The context menu system is now modular via ISContextManager/ISMenuElement. Mods registering entries in `ISWorldMenuElements` or `ISInventoryMenuElements` get automatic integration without touching vanilla code. This makes the delegation pattern even more powerful — modular elements from multiple mods coexist with zIndex priority ordering.

### B42.16 LootWindow Handler Conflicts
Campfire/BBQ/fireplace interactions moved from context menus to persistent LootWindow buttons. Mods that hooked `ISWorldObjectContextMenu` for fire-related actions may see duplicate controls (old context menu entry + new button). Check for and remove legacy hooks when updating to B42.16.

### WorldDictionary Keys
Neat Crafting registers `WorldDictionary` key for persistent state. **Removing mod from save causes crash.** Document this if we use it. Consider ModData alternative.

### Common Conflict Points
- `ISInventoryPage.lua` — Inventory Tetris, CleanUI, Inventory ReInvented all replace
- `ISVehicleDashboard.lua` — Realistic Dashboard, New Car Dashboard, Condition On Dash
- `ISCharacterScreen` structure — Reorganized Info Screen conflicts with KillCount
- B42.16: `ISLootWindowContainerControls` handler registration — mods adding custom handlers with the same `Type` string will overwrite each other
- B42.16: `ISWorldMenuElements` / `ISInventoryMenuElements` — multiple mods registering elements at the same `zIndex` get undefined ordering relative to each other

### Config Persistence
- Modern Status: `ModernStatusConfig.lua` in `Zomboid/Lua/`
- Inventory Tetris: JSON files in `Zomboid/Lua/`
- ZeD approach: ModData for per-save state, ModOptions for preferences
