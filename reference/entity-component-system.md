# Build 42 Entity Component System

## Table of Contents
1. Architecture Overview
2. GameEntity Base
3. Component Types
4. EntitySystem
5. CompLua — The Modding Interface
6. Registry and Namespaces
7. Script Integration

---

## 1. Architecture Overview

Build 42's ECS sits alongside (not replacing) PZ's inheritance hierarchy. `GameEntity` is now the root of both `IsoObject` and `InventoryItem`, but existing class behavior is preserved. The ECS adds **composition** on top of **inheritance** — entities can have arbitrary components attached regardless of their class.

```
Pre-B42:  IsoObject → IsoMovingObject → IsoGameCharacter → IsoPlayer
          InventoryItem → Food, HandWeapon, Clothing, etc.

B42:      GameEntity → IsoObject → ... → IsoPlayer
          GameEntity → InventoryItem → Food, etc.
          + Components attached to any GameEntity
```

This is a hybrid ECS — not pure ECS where entities are just IDs. `GameEntity` instances carry both their class-based behavior and their component bag.

---

## 2. GameEntity Base

```java
public class GameEntity {
    // Component storage
    private Map<ComponentType, Component> components;

    // Script definition
    private GameEntityScript script;

    // Mod data (Lua-accessible KahluaTable)
    private KahluaTable modData;

    // Core methods
    public boolean hasComponent(ComponentType type);
    public <T extends Component> T getComponent(ComponentType type);
    public void addComponent(Component component);
    public void removeComponent(ComponentType type);

    // Lifecycle
    public void update();        // Called each tick
    public void onAdded();       // When entity enters the world
    public void onRemoved();     // When entity leaves the world

    // Data
    public KahluaTable getModData();
    public GameEntityScript getScript();
}
```

### Component Lifecycle

1. **Creation** — Component instances created by script loading or runtime code
2. **Attachment** — `entity.addComponent(component)` — component's `onAttach(entity)` fires
3. **Ticking** — `EntitySystem` calls `component.update()` each tick for active entities
4. **Detachment** — `entity.removeComponent(type)` — component's `onDetach()` fires
5. **Destruction** — When entity is destroyed, all components get `onDetach()`

---

## 3. Component Types

Components live in `zombie.entity.components.*` sub-packages:

### Attributes (`zombie.entity.components.attributes`)

Entity stats and properties — the data layer for game objects.

```java
// Provides typed attribute storage
entity.getComponent(ComponentType.Attributes)
  .getAttribute("health") → AttributeValue
  .setAttribute("health", 100.0)
```

### Crafting (`zombie.entity.components.crafting`)

Crafting station behavior — what recipes a workbench can process, fuel requirements, etc.

```java
entity.getComponent(ComponentType.CraftBench)
  .getRecipes() → list of available recipes
  .canCraft(recipe, player) → boolean
  .startCraft(recipe, player) → void
```

Related: `zombie.entity.components.crafting.recipe` — recipe definitions

### Fluids (`zombie.entity.components.fluids`)

Fluid container and transfer system — water barrels, fuel tanks, etc.

```java
entity.getComponent(ComponentType.FluidContainer)
  .getFluidType() → FluidType
  .getAmount() → float
  .getCapacity() → float
  .addFluid(type, amount) → float (amount actually added)
  .removeFluid(amount) → float (amount actually removed)
```

### Resources (`zombie.entity.components.resources`)

Item storage slots on world objects — the Build 42 replacement for some container patterns.

```java
entity.getComponent(ComponentType.Resources)
  .getSlot(index) → ResourceSlot
  .getSlotCount() → int
```

### Signals (`zombie.entity.components.signals`)

Inter-component communication — components can emit and listen for signals.

```java
entity.getComponent(ComponentType.Signals)
  .emit("signal_name", data)
  .connect("signal_name", listener)
```

### UI (`zombie.entity.components.ui`)

Determines what UI opens when interacting with an entity.

```java
entity.getComponent(ComponentType.UiConfig)
  .getWindowType() → String
  .getWindowClass() → Class<?>
```

This is how Build 42 entities specify their interaction window — the `UiConfig` component tells the engine which `ISBaseEntityWindow` subclass to open.

### CompLua (`zombie.entity.components.lua`)

The primary modding interface — see section 5.

### Context Menu (`zombie.entity.components.contextmenu`)

```java
entity.getComponent(ComponentType.ContextMenuConfig)
  // Defines custom context menu entries for the entity
```

### Parts (`zombie.entity.components.parts`)

Multi-part entities (e.g., complex crafting stations with multiple sub-components).

### Sprite Config (`zombie.entity.components.spriteconfig`)

Controls entity visual representation.

### Combat (`zombie.entity.components.combat`)

Combat-related component data.

---

## 4. EntitySystem

`zombie.entity.system.EntitySystem` manages entity lifecycle and queries:

```java
public class EntitySystem {
    // Entity registry
    private Map<Long, GameEntity> entities;

    // Component queries
    public List<GameEntity> getEntitiesWithComponent(ComponentType type);
    public void forEachEntity(Consumer<GameEntity> action);

    // Lifecycle
    public void update();  // Ticks all active entities
    public void addEntity(GameEntity entity);
    public void removeEntity(GameEntity entity);
}
```

The `update()` loop iterates active entities and calls `component.update()` on each component. This is separate from PZ's existing `OnTick` event loop — ECS updates happen in the entity system's own cycle.

---

## 5. CompLua — The Modding Interface

`CompLua` (in `zombie.entity.components.lua`) is TIS's designated modding hook for the ECS. It allows Lua code to define component behavior that runs within the entity system.

```lua
-- From Lua, attaching behavior to an entity:
local entity = someWorldObject:getEntity()
local compLua = entity:getComponent(ComponentType.CompLua)
if compLua then
    -- Access Lua-side component data
    compLua:setData("myMod_state", "active")
    compLua:getData("myMod_state")
end
```

`CompLua` bridges the ECS (Java) and modding (Lua) layers. It stores arbitrary key-value data accessible from both sides and can trigger Lua callbacks during entity lifecycle events.

This is the primary forward-looking modding interface. TIS has signaled that ECS + CompLua is the intended direction for new mod development, alongside the established ISUI/event system.

---

## 6. Registry and Namespaces

Build 42 introduced a namespaced registry system inspired by Minecraft:

```
Format: namespace:path
Examples:
  base:axe           (vanilla item)
  mymod:custom_bench (modded item)
```

The registry system allows mods to register entries (items, recipes, entity types, etc.) with unique namespaced identifiers. This prevents name collisions between mods and provides a clean lookup mechanism.

```java
// Java side
ResourceLocation location = new ResourceLocation("mymod", "custom_bench");
Registry.register(location, myEntityScript);

// Lua side (exposed via global functions)
local item = instanceItem("mymod:custom_bench")
```

### Namespace Rules

- `base` — reserved for vanilla content
- Mod namespaces should match the mod ID from `mod.info`
- Paths use lowercase with underscores
- Colons separate namespace from path

---

## 7. Script Integration

Entity scripts (`zombie.scripting.entity.*`) define the component composition of entities:

```java
// zombie.scripting.entity.GameEntityScript
public class GameEntityScript {
    private ResourceLocation id;
    private List<ComponentScript> components;

    // When an entity is created from this script:
    public GameEntity createEntity() {
        GameEntity entity = new GameEntity();
        for (ComponentScript cs : components) {
            entity.addComponent(cs.createComponent());
        }
        return entity;
    }
}
```

Script files (text-based, in `media/scripts/`) define what components an entity has:

```
entity MyWorkbench {
    component CraftBench {
        recipes = MyRecipe1;MyRecipe2,
    }
    component UiConfig {
        windowType = ISCraftBenchUI,
    }
    component Resources {
        slots = 4,
    }
}
```

The scripting system compiles these definitions into `GameEntityScript` objects, which serve as templates for creating `GameEntity` instances at runtime.

---

## 8. Build 42.16 ECS Changes

### Fluid Container Realtime Sync

`ISFluidTransferAction:update()` now calls `source:sync()` and `target:sync()` every tick during fluid transfers. This pushes partial fill states to the UI in realtime — containers visually update as they fill rather than jumping to the final amount on completion. The `FluidContainer.Transfer()` static method handles the per-tick transfer math.

### Entity UI Resolution

New Lua-side helper functions for resolving entity UI configuration:

```lua
ISEntityUI.GetEntityUiConfig(_entity)   -- Returns UiConfig component
ISEntityUI.GetEntityUiStyle(_entity)    -- Returns style identifier string
ISEntityUI.GetEntityUiSkin(_entity)     -- Returns skin identifier
ISEntityUI.GetComponentPanelClass()     -- Resolves component panel class with validation
```

Component iteration uses `_entity:componentSize()` and `_entity:getComponentForIndex(i)` for index-based access alongside the existing `hasComponent()`/`getComponent()` type-based access.

### CraftBenchSounds Component

B42.16 references a `ComponentType.CraftBenchSounds` component for audio feedback on crafting stations, alongside the existing `CraftBench` component.

### Distribution System Fixes (Java-side)

The distribution system (which populates container items in the world) had two Java-side fixes:

1. **procList weightChance default**: `Distributions.lua` entries in `procList` tables that omitted `weightChance` previously failed the spawn check entirely. The Java-side resolver now handles missing `weightChance` gracefully.

2. **ForceForZones enforcement**: The `forceForZones` field on distribution entries (values like "Rich", "TrailerPark", "Poor") was not being checked against the room's zone type. Now properly enforced — entries with `forceForZones` only spawn in matching zones.

### New B42 Skill Categories for VHS Codes

VHS media learning codes now support additional B42 skill categories. The `recorded_media.lua` system uses shorthand codes (e.g., `AIM+1`, `COO+1`, `MTL+1`) mapped to Perks enum values. New codes include metalworking, building, and other B42-era skills. Modders can register custom VHS tapes with skill learning via these codes for future modding utilization.
