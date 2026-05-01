# PZ Java Class Hierarchy — Complete Reference

## Table of Contents
1. Root: zombie.entity.GameEntity
2. Characters (zombie.characters)
3. Inventory (zombie.inventory)
4. World Objects (zombie.iso)
5. Vehicles (zombie.vehicles)
6. UI (zombie.ui)
7. Lua Bridge (zombie.Lua)
8. Scripting (zombie.scripting)
9. Core Systems
10. Key Package Index

---

## 1. Root: zombie.entity.GameEntity

Build 42 introduced `GameEntity` as the root of the game object model. It replaced `Object` as the base for both `IsoObject` and `InventoryItem`.

```
GameEntity
  ├── hasComponents() → boolean
  ├── getComponent(ComponentType) → Component
  ├── addComponent(Component) → void
  ├── removeComponent(ComponentType) → void
  ├── getEntity() → GameEntity (self-reference for interface compat)
  ├── getScript() → GameEntityScript
  └── getModData() → KahluaTable
```

`GameEntity` owns the component storage and lifecycle. The `getModData()` method returns a `KahluaTable` — this is the primary mechanism for Lua mods to store custom data on any game object.

---

## 2. Characters (zombie.characters)

### Primary Hierarchy

```
GameEntity
  └── IsoObject
        └── IsoMovingObject
              └── IsoGameCharacter (abstract)
                    ├── IsoLivingCharacter
                    │     ├── IsoPlayer (final)
                    │     └── IsoSurvivor
                    ├── IsoZombie
                    └── IsoAnimal (Build 42)
```

### IsoGameCharacter — Key Methods

**Combat & Damage:**
- `Hit(HandWeapon, IsoGameCharacter, float, boolean, float, boolean)` — primary attack
- `processHitDamage(HandWeapon, IsoGameCharacter, float)` — damage calculation
- `getHealth()` / `setHealth(float)` — 0.0 = dead, 1.0 = full
- `getBodyDamage()` → `BodyDamage` (body part damage system)

**State & Stats:**
- `getStats()` → `Stats` (hunger, thirst, fatigue, stress, pain, etc.)
- `getMoodles()` → `Moodles` (mood indicators)
- `getNutrition()` → `Nutrition` (calories, protein, carbs, lipids, weight)
- `getXp()` → `XP` (experience tracking)
- `getPerkLevel(Perks)` → int

**Equipment:**
- `getPrimaryHandItem()` / `setPrimaryHandItem(InventoryItem)` → `InventoryItem`
- `getSecondaryHandItem()` / `setSecondaryHandItem(InventoryItem)` → `InventoryItem`
- `getWornItems()` → `WornItems` (iterable worn clothing)
- `getClothingItem_Back()`, `_Hands()`, etc. → slot-specific access

**Movement & State:**
- `changeState(State)` — AI state machine transition
- `Say(String)` / `SayShout(String)` — speech/shout
- `getVehicle()` → `BaseVehicle` (if in vehicle)
- `getCurrentSquare()` → `IsoGridSquare`

**Inner Classes:**
- `IsoGameCharacter.BodyLocation` — equipment slot enum
- `IsoGameCharacter.CharacterTraits` — trait definitions
- `IsoGameCharacter.XP` — XP tracking per perk
- `IsoGameCharacter.PerkInfo` — perk metadata

### IsoPlayer — Key Additions

- `getPlayerNum()` → int (0-3, split-screen index)
- `getInventory()` → `ItemContainer`
- `getUsername()` → String (MP)
- `getSteamID()` → long (MP)
- `isLocalPlayer()` → boolean
- `getJoypadBind()` → int (-1 = keyboard)
- `getHoursSurvived()` → float
- `getKills()` → int (zombie kills)
- `getTimeSinceLastSmoke()` → float
- `setJoypadIgnoreAimUntilCentered(boolean)` → void **(B42.16)** — prevents aiming during UI interactions when using gamepad. Called by all radial menus and custom gamepad UIs.

**B42.16 Input Rework:** IsoPlayer's input handling was revamped to share bindings between keyboard+mouse and gamepad. Input events (`OnKeyStartPressed`, `OnKeyKeepPressed`, `OnKeyPressed`) now fire identically for both input methods. Aiming thresholds: 1% stick deflection activates aim, 99% triggers shoot. Movement threshold: under 90% for walking, over 90% for running. Aim center uses character offset at chest height.

### IsoAnimal — B42.16 Additions

- Baby animal connections now persist through trailer load/unload cycles
- Milk production rate adjusted (animals no longer lose milk too fast, preventing baby starvation)
- Raccoon kits now have the kill-by-hand tag
- Animal trailers weight increased from 100 to 500 (prevents zombie-touch flipping)

### Supporting Packages

**zombie.characters.BodyDamage:**
- `BodyDamage` — overall body damage state
- `BodyPart` — individual body part (each has scratched, bleeding, bitten, deepWounded, burnTime, fractureTime, stiffness)
- `BodyPartType` — enum of all body parts
- `Thermoregulator` — temperature regulation

**zombie.characters.Moodles:**
- `MoodleType` — enum (Hungry, Thirsty, Tired, Bored, Unhappy, Sick, etc.)
- `Moodle` — individual moodle state with levels 1-4

**zombie.characters.skills:**
- `PerkFactory` — perk definitions
- `PerkFactory.Perks` — enum of all perks (Cooking, Farming, Fishing, etc.)

**zombie.characters.action (Build 42):**
- `ActionContext` — action execution context
- `ActionGroup` — grouped actions
- Expanded from Build 41's simpler timed action system

---

## 3. Inventory (zombie.inventory)

### Primary Hierarchy

```
GameEntity
  └── InventoryItem
        ├── Clothing (+ AlarmClockClothing)
        ├── Food
        ├── HandWeapon
        ├── InventoryContainer
        ├── Literature
        ├── DrainableComboItem (implements Drainable)
        ├── WeaponPart
        ├── Key, KeyRing
        ├── MapItem
        ├── Moveable
        ├── Radio
        └── AnimalInventoryItem (Build 42)
```

### InventoryItem — Key Methods

- `getType()` → String (e.g., "Base.Axe")
- `getFullType()` → String (module-qualified)
- `getName()` / `getDisplayName()` → String
- `getWeight()` → float
- `getActualWeight()` → float (includes contents)
- `getCondition()` / `setCondition(int)` → int
- `getMaxCondition()` → int
- `getTexture()` → Texture
- `getIcon()` → String (icon path)
- `getContainer()` → ItemContainer (if it holds items)
- `getModData()` → KahluaTable
- `getScriptItem()` → Item (script definition)
- `IsWeapon()`, `IsFood()`, `IsClothing()`, etc. → boolean type checks
- `canEmitLight()` → boolean

### ItemContainer

- `getItems()` → ArrayList<InventoryItem>
- `AddItem(InventoryItem)` → InventoryItem
- `Remove(InventoryItem)` → void
- `contains(InventoryItem)` → boolean
- `getItemFromType(String)` → InventoryItem
- `getCapacity()` / `getContentsWeight()` → float
- `getType()` → String (container type identifier)

### InventoryItemFactory

- `CreateItem(String fullType)` → InventoryItem (the primary creation method)
  - Determines subclass from script definition
  - Reads item properties from `zombie.scripting.objects.Item`

### Food — Key Additions

- `getHungerChange()` → float (negative = reduces hunger)
- `getThirstChange()` → float
- `getCalories()`, `getProteins()`, `getCarbohydrates()`, `getLipids()` → float
- `isCooked()`, `isBurnt()`, `isRotten()` → boolean
- `getCookingTime()`, `getOffAge()`, `getOffAgeMax()` → float
- `getPoisonPower()` → float

### HandWeapon — Key Additions

- `getMinDamage()` / `getMaxDamage()` → float
- `getCriticalChance()` → float
- `getMinRange()` / `getMaxRange()` → float
- `isRanged()` → boolean
- `getAmmoType()` → String
- `getClipSize()` → int
- `getCurrentAmmoCount()` → int

---

## 4. World Objects (zombie.iso)

### IsoObject — Key Methods

- `getSquare()` → IsoGridSquare
- `getX()`, `getY()`, `getZ()` → float (world coordinates)
- `getSprite()` → IsoSprite
- `getContainer()` → ItemContainer (if object has storage)
- `getModData()` → KahluaTable
- `getTable()` → KahluaTable (legacy mod data — same as getModData for most objects)
- `getProperties()` → PropertyContainer (sprite properties)
- `getObjectName()` → String
- `getEntity()` → GameEntity (Build 42)

### Spatial Structure

```
IsoWorld (singleton)
  └── IsoCell (active loaded area, typically 1)
        └── IsoChunk (16×16 tiles, loaded/unloaded dynamically)
              └── IsoGridSquare (single tile — the fundamental spatial unit)
                    ├── List<IsoObject> objects (stacked objects on tile)
                    ├── getRoom() → IsoRoom
                    ├── getBuilding() → IsoBuilding  
                    ├── getFloor() → IsoObject
                    └── getMovingObjects() → List<IsoMovingObject>
```

### Key IsoObject Subclasses

| Class | Purpose | Key Methods |
|---|---|---|
| `IsoWorldInventoryObject` | Items on ground | `getItem()` → InventoryItem |
| `IsoThumpable` | Player-built | `getHealth()`, `getMaxHealth()` |
| `IsoDoor` | Doors | `isOpen()`, `isLocked()`, `IsOpen(boolean)` |
| `IsoWindow` | Windows | `isSmashed()`, `isBarricaded()` |
| `IsoBarricade` | Barricades | `getHealth()`, `getMaxHealth()` |
| `IsoStove` | Stoves | `isActivated()`, `getTemperature()` |
| `IsoGenerator` | Generators | `getFuel()`, `isActivated()` |
| `IsoFire` | Fire sources | `getLifeStage()` |
| `IsoTree` | Trees | — |
| `BSFurnace` (B42) | Blast furnace | Component-based crafting |
| `IsoCompost` (B42) | Composting | Component-based |
| `IsoMannequin` (B42) | Mannequins | Equipment display |

---

## 5. Vehicles (zombie.vehicles)

```
IsoMovingObject → BaseVehicle
```

- `getDriver()` → IsoGameCharacter
- `getPassenger(int seat)` → IsoGameCharacter
- `getEngineSpeed()` → float
- `getCurrentSpeedKmHour()` → float
- `getPartById(String)` → VehiclePart
- `getScript()` → VehicleScript

---

## 6. UI (zombie.ui)

Java-side UI is minimal compared to the Lua ISUI system:

```
UIElement (base)
  ├── UIManager (static manager)
  └── NewWindow (Java-side window wrapper)
```

`UIManager` methods:
- `AddUI(UIElement)` / `RemoveElement(UIElement)` — register/unregister
- `getUI()` → ArrayList<UIElement>
- `setShowPausedMessage(boolean)` — pause screen control
- `bSuspend` — suspend UI updates

Most UI work happens in Lua via ISUI (`pz-modding`'s territory).

---

## 7. Lua Bridge (zombie.Lua)

### Class Hierarchy

```
LuaManager (static orchestrator)
  ├── LuaManager.GlobalObject (inner class → global Lua functions)
  ├── LuaManager.Exposer (extends LuaJavaClassExposer)
  └── LuaManager.Run (script execution)

LuaEventManager (implements JavaFunction)
  └── Maintains ArrayList<LuaClosure> per event name

LuaHookManager (implements JavaFunction)
  └── Similar to LuaEventManager for hooks
```

See `references/exposure-system.md` for the deep dive.

---

## 8. Scripting (zombie.scripting)

The scripting system defines game content — items, recipes, vehicles, etc. — via text-based script files that compile to Java objects.

```
zombie.scripting.objects:
  ├── Item extends GameEntityScript (item definitions)
  ├── Recipe (crafting recipes)
  ├── VehicleScript (vehicle definitions)
  ├── ModelScript (3D model definitions)
  └── ... (many more)
```

`ScriptManager` loads and manages all script definitions. Items defined in scripts create `InventoryItem` subclass instances through `InventoryItemFactory`.

---

## 9. Core Systems

### zombie.core
- `Core` — singleton, game configuration and state
- `Rand` — random number generator
- `Color` — RGBA color (float-based)
- `SpriteRenderer` — rendering pipeline
- `Texture` — texture loading and management

### zombie.network
- `GameClient` / `GameServer` — multiplayer
- `ServerOptions` — server configuration
- `PacketTypes` — network protocol

### zombie.gameStates
- `MainScreenState`, `IngameState`, `LoadingQueueState`, etc.
- `GameStateMachine` — state transition manager

### zombie.debug
- `DebugLog` — categorized logging (`DebugType` enum)
- `DebugOptions` — runtime debug toggles

### zombie.input
- `Mouse`, `JoypadManager`, `GameKeyboard` — input handling

---

## 10. Key Package Index

| Package | Contents | Line Count (approx) |
|---|---|---|
| `zombie.characters` | Character classes + AI | Major |
| `zombie.characters.BodyDamage` | Body part damage system | ~20 classes |
| `zombie.characters.Moodles` | Mood indicators | ~5 classes |
| `zombie.characters.skills` | Perks and XP | ~10 classes |
| `zombie.characters.action` | Action system (B42 expanded) | ~15 classes |
| `zombie.inventory` | Item classes + containers | Major |
| `zombie.iso` | World objects + spatial grid | Major |
| `zombie.iso.sprite` | Sprite rendering | ~15 classes |
| `zombie.entity` | GameEntity base | ~10 classes |
| `zombie.entity.components.*` | ECS components | ~50+ classes |
| `zombie.entity.system` | Entity lifecycle | ~5 classes |
| `zombie.Lua` | Lua bridge | ~10 classes |
| `zombie.scripting` | Script loading + definitions | ~30 classes |
| `zombie.ui` | Java-side UI | ~10 classes |
| `zombie.vehicles` | Vehicle system | ~20 classes |
| `zombie.network` | Multiplayer | Major |
| `zombie.core` | Engine core | ~30 classes |
