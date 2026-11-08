# Kahlua2 and Project Zomboid's Java-Lua engine architecture

**Project Zomboid runs its entire modding layer on Kahlua2, a pure-Java implementation of Lua 5.1 that maps Lua types directly to JVM objects and exposes Java classes to Lua through reflection-backed metatables.** This architecture means every `player:getHealth()` call in Lua traverses a metatable inheritance chain, resolves a cached `java.lang.reflect.Method`, and invokes it through Kahlua's `LuaJavaInvoker` — no JNI, no native code, no bytecode generation. Understanding this bridge is essential for reading PZ's engine layer, because the Java class hierarchy, the Kahlua exposure system, and the Lua API are three views of one unified object model. Build 42 introduced a full Entity Component System beneath the existing class tree, fundamentally reshaping how game objects work at the Java level.

---

## How Kahlua2 implements Lua on the JVM

Kahlua was created by Kristofer Karlsson in 2007 as a **clean-room reimplementation** of Lua 5.1 — not a port of C Lua, but a ground-up Java design reverse-engineered from the Lua reference manual. Originally targeting J2ME phones (CLDC 1.1), it was redesigned as Kahlua2 around 2010 with modularity, concurrency support, and a Java integration layer. The package namespace is `se.krka.kahlua` (not `se.krka.kahlua2`).

### Type system bridge

Kahlua maps Lua types directly to Java boxed types with zero wrapper overhead:

| Lua type | Java type | Notes |
|---|---|---|
| `nil` | `null` | Direct mapping |
| `number` | `java.lang.Double` | All numbers are boxed doubles |
| `boolean` | `java.lang.Boolean` | `Boolean.TRUE` / `Boolean.FALSE` singletons |
| `string` | `java.lang.String` | UTF-16 (Java native), not Lua's byte-oriented strings |
| `table` | `KahluaTable` interface | `KahluaTableImpl` backed by `ConcurrentHashMap` on J2SE |
| `function` (Lua) | `LuaClosure` | Closure wrapping a compiled `Prototype` |
| `function` (Java) | `JavaFunction` interface | Single method: `int call(LuaCallFrame, int nArguments)` |
| `coroutine` | `Coroutine` | Independent call stack, stackful continuation model |
| `userdata` | Any `Object` | **Any Java object becomes userdata** — metatables set per exact class |

Type detection in `KahluaUtil.type()` uses `instanceof` checks in this exact order: `null` → `String` → `Double` → `Boolean` → `JavaFunction`/`LuaClosure` → `KahluaTable` → `Coroutine` → fallback `"userdata"`. This fallback is critical: it means every PZ Java object (IsoPlayer, InventoryItem, etc.) appears to Lua as type `"userdata"` with behavior defined entirely by its class metatable.

### The VM execution engine: KahluaThread

`KahluaThread` (1,255 lines) is the central bytecode interpreter, replacing Kahlua v1's `LuaState`. It implements all **38 standard Lua 5.1 opcodes** (OP_MOVE through OP_VARARG) in a single `luaMainloop()` method containing a large switch statement over 32-bit instruction words. The bytecode format is standard Lua 5.1 binary format — files compiled by the C `luac` tool work directly.

Key architectural elements inside KahluaThread:

- **`currentCoroutine`** holds the active `Coroutine`, which owns the `Object[] objectStack` (the Lua value stack) and the `LuaCallFrame[]` call stack
- **`call(int nArguments)`** dispatches based on the callable's type: `JavaFunction` goes to `callJava()`, `LuaClosure` pushes a new `LuaCallFrame` and enters `luaMainloop()`
- **`tableGet(Object table, Object key)`** implements `__index` resolution with a recursive chain (up to `MAX_INDEX_RECURSION` depth), checking `rawget` first, then falling through to `__index` metamethods — which can be either a function (called with the table and key) or another table (traversed recursively)
- **`tableSet(Object table, Object key, Object value)`** mirrors this pattern for `__newindex`
- **`getMetaOp(Object o, String metaMethodName)`** resolves metamethods — for `KahluaTable` instances it reads the per-instance metatable, for arbitrary Java objects it uses a **class→metatable mapping** stored in the exposer

Lua errors map to Java `RuntimeException`. The `pcall` implementation catches these and returns `false, errormessage, stacktrace, original_java_exception` — PZ error logs always show this four-value pattern.

### Coroutines without Java threads

Kahlua2 coroutines are **pure stackful continuations** — they do NOT use Java threads. Each `Coroutine` object owns its own `objectStack[]` and `callFrameStack[]`. When `coroutine.resume()` fires, `KahluaThread` swaps `currentCoroutine` to the target and continues `luaMainloop()`. When `coroutine.yield()` fires, execution state is saved in the call frame stack and control returns to the parent coroutine. This is lighter than LuaJ's Java-thread-based coroutines but means coroutines cannot yield across Java call boundaries.

### What Kahlua2 deliberately drops from Lua 5.1

Kahlua2 trades full Lua compatibility for Java-idiomatic design: **no `next()` function** (incompatible with `ConcurrentHashMap` iteration semantics), **no weak tables** (`__mode` metatables are ignored), **no `__gc` metamethod** (JVM handles garbage collection), **no `io.*` or `debug.*` libraries**, and **no special 0/-0 key distinction** in tables. String interning was removed to avoid PermGen pressure. These tradeoffs matter for PZ modders — `next()` unavailability means `pairs()` uses Kahlua's `KahluaTableIterator` instead.

---

## Kahlua2's modular architecture and Java integration layer

Kahlua2 splits into four modules: **core** (platform-independent VM, stdlib, compiler), **j2se** (J2SE platform with `ConcurrentHashMap`-backed tables, converter framework, annotation-based exposure), **cldc11** (J2ME platform with `Hashtable`-backed tables), and **interpreter** (interactive shell). PZ uses core + j2se.

### The Platform abstraction

```java
public interface Platform {
    double pow(double x, double y);
    KahluaTable newTable();
    KahluaTable newEnvironment();
}
```

`J2SEPlatform` (singleton via `getInstance()`) creates tables backed by `ConcurrentHashMap<Object, Object>` and populates environments with BaseLib, MathLib, StringLib, CoroutineLib, OsLib, TableLib, RandomLib, and the LuaJ-forked compiler.

### KahluaTable interface and implementation

The `KahluaTable` interface defines: `rawget(Object key)`, `rawset(Object key, Object value)`, `rawget(int key)`, `rawset(int key, Object value)`, `getMetatable()`, `setMetatable(KahluaTable)`, `len()`, `iterator()`, `isEmpty()`, `wipe()`. The J2SE implementation wraps `ConcurrentHashMap`, which enables safe concurrent read/write from multiple `KahluaThread` instances sharing one environment. This is how PZ handles its multi-threaded architecture — multiple `KahluaThread` objects share a single global `KahluaTable` environment.

### Converter and exposer system

The J2SE module provides a full Java↔Lua integration layer:

- **`KahluaConverterManager`** — central registry for bidirectional converters. Built-in converters handle `int/long/float` → `Double` (`KahluaNumberConverter`), Java enums ↔ Lua strings (`KahluaEnumConverter`), and Java Maps/Lists ↔ `KahluaTable` (`KahluaTableConverter`)
- **`LuaCaller`** — protected-call wrapper that applies converters to inputs and returns structured `LuaReturn` objects (with `isSuccess()`, `getErrorMessage()`, `getStacktrace()`, `getJavaException()`)
- **`LuaJavaClassExposer`** — the key class that scans Java classes and creates Lua metatables with `__index` tables containing `LuaJavaInvoker` entries for each method
- **`@LuaMethod`** annotation with `name` (optional rename) and `global` (boolean) parameters
- **`@LuaConstructor`** annotation for exposing constructors as global Lua functions
- **`LuaJavaInvoker`** wraps a single `java.lang.reflect.Method` as a `JavaFunction`
- **`MultiLuaJavaInvoker`** handles Java method overloading by maintaining a sorted list of invokers, selecting the best match by parameter count at call time

---

## How Project Zomboid bridges Java to Lua

PZ's Lua layer lives in the `zombie.Lua` package, centered on `LuaManager` — a static class that initializes and orchestrates the entire Lua environment.

### LuaManager's static architecture

| Field | Type | Purpose |
|---|---|---|
| `platform` | `J2SEPlatform` | Platform abstraction |
| `env` | `KahluaTable` | Global Lua environment |
| `thread` | `KahluaThread` | Main execution thread |
| `debugthread` | `KahluaThread` | Separate debug thread |
| `caller` | `LuaCaller` | Protected-call wrapper |
| `exposer` | `LuaManager.Exposer` | PZ's subclass of `LuaJavaClassExposer` |
| `converterManager` | `KahluaConverterManager` | Type conversion registry |

`LuaManager.init()` creates the platform, environment, and thread, then calls `exposer.exposeAll()` to batch-expose all game API classes. `LuaManager.GlobalObject` is a static inner class whose methods become **global Lua functions** — `getPlayer()`, `getGameTime()`, `instanceItem()`, `getWorld()`, `sendClientCommand()`, and hundreds more are exposed via `exposeGlobalFunctions()`.

### The Exposer: how Java classes become Lua-callable

`LuaManager.Exposer` extends Kahlua2's `LuaJavaClassExposer` with a **whitelist gatekeeper** (`shouldExpose(Class)`) that controls which classes are accessible from Lua. PZ uses primarily `exposeLikeJava(Class, environment)` — which exposes **all public methods** of a Java class without requiring `@LuaMethod` annotations. This walks the class hierarchy recursively to expose inherited methods.

When a class is first exposed, `setupMetaTables` creates this structure:

```
Class metatable (KahluaTable)
  ├── "__index" → indexTable (KahluaTable containing LuaJavaInvoker entries)
  ├── "__newindex" → inherited from parent
  └── "__eq" → JavaFunction delegating to Object.equals()

indexTable's own metatable → parent class's metatable (inheritance chain)
```

This creates a **Lua-style prototype chain mirroring Java's class hierarchy**. When Lua accesses `player:getHealth()`, if `getHealth` isn't in `IsoPlayer`'s indexTable, it walks up through `IsoGameCharacter` → `IsoMovingObject` → `IsoObject` → `GameEntity`.

### The complete call chain for `player:getHealth()`

Every method call from Lua to Java follows this exact path:

1. **KahluaThread.luaMainloop()** encounters `GETTABLE` opcode for `player.getHealth` (Lua desugars `player:getHealth()` to `player.getHealth(player)`)
2. **KahluaThread.tableget(player, "getHealth")** — player is a Java `IsoPlayer` object, not a `KahluaTable`. Looks up `IsoPlayer.class` in `classMetatables`, finds the metatable, follows `__index` to the indexTable, finds a `LuaJavaInvoker`
3. **KahluaThread.luaMainloop()** encounters `CALL` opcode — the `LuaJavaInvoker` implements `JavaFunction`, so dispatches to `callJava()`
4. **KahluaThread.callJava()** pushes a new `LuaCallFrame` and calls `LuaJavaInvoker.call(callFrame, nArguments)`
5. **LuaJavaInvoker.call()** extracts the self object from `callFrame.get(0)`, converts Lua args to Java types via `KahluaConverterManager`, delegates to `MethodCaller.call()`
6. **MethodCaller** wraps `java.lang.reflect.Method` — calls `method.invoke(ownerObject, convertedArgs)` (JDK generates a `GeneratedMethodAccessor` bytecode class after ~15 invocations for performance)
7. **Return path**: Java return value flows back through the converter (e.g., `int` → `Double`), gets pushed onto the call frame stack, control returns to `luaMainloop()`

This is confirmed by real PZ stack traces:
```
java.lang.reflect.Method.invoke(Unknown Source)
se.krka.kahlua.integration.expose.caller.MethodCaller.call(MethodCaller.java:62)
se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:198)
se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:182)
se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:1007)
```

**Method caching is at exposure time, not call time.** The `Method` object is stored inside `LuaJavaInvoker` when the class is first exposed. No reflective method lookup happens during gameplay — only `Method.invoke()`. For overloaded methods, `MultiLuaJavaInvoker` maintains a sorted list of invokers and selects the best match by parameter count.

### Critical limitation: no field access from Lua

**Java class fields are not accessible from Lua regardless of visibility.** Access to Java object state goes exclusively through getter/setter methods: `player:getHealth()`, not `player.health`. When Lua code does `object.someProperty`, the `__index` metamethod fires, looks for `"someProperty"` in the indexTable, and returns `nil` if no method by that name exists. There is no automatic field-to-property mapping.

### Event system: Java triggering Lua callbacks

PZ's event system bridges Java game events to Lua:

```
Java game code → LuaEventManager.triggerEvent("OnTick")
  → Event.trigger(env, caller, params)
    → LuaCaller.protectedCallVoid(closure)
      → KahluaThread.pcall(closure)
        → KahluaThread.luaMainloop()
```

`LuaEventManager` and `LuaHookManager` both implement `JavaFunction` and maintain `ArrayList<LuaClosure>` callback lists. Lua registers via `Events.OnTick.Add(myFunction)`.

---

## PZ's Java class hierarchy: the engine object model

The codebase lives under the root `zombie` package with **150+ sub-packages** and thousands of classes. Build 42's most transformative change was introducing `zombie.entity.GameEntity` as a new base class, creating an Entity Component System beneath the existing inheritance tree.

### Character hierarchy (zombie.characters)

```
GameEntity (Build 42)
  └── IsoObject (implements Serializable, Thumpable)
        └── IsoMovingObject (implements Mover)
              └── IsoGameCharacter (abstract; implements IAnimatable,
                    │   ILuaGameCharacter, ILuaVariableSource, + 8 more)
                    ├── IsoLivingCharacter
                    │     ├── IsoPlayer (final; implements IHumanVisual)
                    │     └── IsoSurvivor
                    ├── IsoZombie
                    └── IsoAnimal (Build 42 — animal husbandry)
```

`IsoGameCharacter` is the abstract workhorse with inner classes for `BodyLocation`, `CharacterTraits`, `XP`, `PerkInfo`. Key methods: `Hit()`, `processHitDamage()`, `Say()`, `getPrimaryHandItem()`, `getSecondaryHandItem()`, `changeState()`. Supporting packages include `zombie.characters.BodyDamage` (body part damage), `zombie.characters.Moodles` (mood indicators), `zombie.characters.skills` (`PerkFactory`, `PerkFactory.Perks`), and `zombie.characters.action` (Build 42's expanded action system with `ActionContext`, `ActionGroup`).

### Inventory hierarchy (zombie.inventory)

```
GameEntity (Build 42)
  └── InventoryItem
        ├── Clothing (+ AlarmClockClothing)
        ├── Food (nutrition data, cooking state)
        ├── HandWeapon (melee + ranged weapons)
        ├── InventoryContainer (bags, containers)
        ├── Literature (books, magazines, maps)
        ├── DrainableComboItem (implements Drainable)
        ├── WeaponPart (attachments/modifications)
        ├── Key, KeyRing, MapItem, Moveable, Radio
        └── AnimalInventoryItem (Build 42)
```

In Build 41, `InventoryItem` extended `Object`; in **Build 42 it extends `GameEntity`**, meaning all items are now entities that can have components attached. Items are created via `InventoryItemFactory.CreateItem("Module.ItemName")` — the subclass is determined by the script definition, not chosen manually. The scripting counterpart is `zombie.scripting.objects.Item extends GameEntityScript`.

### World spatial hierarchy (zombie.iso)

```
GameEntity
  └── IsoObject
        ├── IsoMovingObject → (character hierarchy above)
        │     └── BaseVehicle (zombie.vehicles)
        ├── IsoWorldInventoryObject (items on the ground)
        ├── IsoThumpable (player-built structures)
        ├── IsoDoor, IsoWindow, IsoCurtain, IsoBarricade
        ├── IsoTree, IsoFire, IsoStove, IsoGenerator
        ├── IsoMannequin, IsoCompost, BSFurnace (Build 42)
        └── ... (30+ more subclasses)
```

The spatial structure is `IsoWorld` (singleton) → `IsoCell` (active loaded area) → `IsoChunk` (16×16 tiles) → `IsoGridSquare` (single tile, the fundamental spatial unit containing `List<IsoObject>`). Every `IsoObject` has a `table` field (`KahluaTable`) for Lua mod data, a `container` field (`ItemContainer`) for stored items, a `square` field for its tile location, and a `sprite` field for visual representation.

### UI architecture: Java backing, Lua surface

`UIElement` (Java) is the base class for all UI elements, with `UIManager` as the static manager. But modders work almost exclusively with the **Lua ISUI system** — `ISUIElement` and its derivatives (`ISButton`, `ISPanel`, `ISCollapsableWindow`, `ISScrollingListBox`, etc.) defined in `media/lua/client/ISUI/`. The Lua widgets register as UIElement instances through `UIManager.AddUI()`. The Java side handles rendering, input, and positioning; the Lua side builds complex interactive widgets.

---

## Build 42's Entity Component System

Build 42 introduced a full ECS under `zombie.entity`, the most significant architectural change in PZ's history. Both `IsoObject` and `InventoryItem` now extend `GameEntity`, meaning world objects and inventory items are **composable entities** rather than purely inheritance-defined.

### Component packages (zombie.entity.components.*)

| Package | Purpose |
|---|---|
| `.attributes` | Entity stats and properties |
| `.crafting` / `.crafting.recipe` | Crafting stations and recipe definitions |
| `.fluids` | Fluid container and transfer system |
| `.lua` | **`CompLua`** — Lua-driven components (key modding interface) |
| `.combat` | Combat-related components |
| `.parts` | Multi-part entity components |
| `.resources` | Resource management |
| `.signals` | Signal/event components |
| `.spriteconfig` | Sprite configuration |
| `.ui` | UI-related entity components |

The `zombie.entity.system.EntitySystem` manages entity lifecycle and component queries. Script counterparts in `zombie.scripting.entity.components.*` mirror runtime components. Build 42 also introduced a **namespaced ResourceLocation/Registry system** (`namespace:path` format, similar to Minecraft's) that allows mods to register entries with their own namespaces.

---

## PZ's modifications to upstream Kahlua2

PZ's fork diverges from Kahlua2 in several documented ways. `LuaManager.Exposer.shouldExpose(Class)` acts as a whitelist gatekeeper — only developer-approved classes are accessible. The Lua environment is **partially sandboxed**: `io.*`, `os.*`, and Java reflection are blocked. PZ added `LuaBackendClass`, a class implementing `KahluaTable` that allows certain PZ objects to behave as both Java objects and Lua tables simultaneously. Build 42 added Lua Exposer warnings when methods are accidentally overwritten by fields, and improved the Lua debugger to display elements in `java.util.List` subclasses and `ItemContainer.Items`.

---

## Community tooling for reading PZ's Java source

Since PZ ships as compiled `.class` files, the modding community has built specialized decompilation tooling:

- **Zomboid Decompiler** (demiurgeQuantified) — the current recommended tool, powered by **Vineflower** (modern FernFlower fork). Integrates PZ's JavaDocs for readable variable names. Supports remote debugging via line remapping. Requires Java 17+, auto-detects Steam installation
- **Beautiful Java** (quarantin) — produces clean variable names, originally Linux-only
- **Capsid** (pzstorm) — Gradle plugin integrating FernFlower with automated workflow: `decompileZomboid` → `annotateZomboid` → `compileZomboid`
- **Unofficial Build 42 JavaDocs** (demiurgeQuantified) at `demiurgequantified.github.io/ProjectZomboidJavaDocs/`, with AI-generated architectural analysis at DeepWiki

Java modding (modifying `.class` files directly) is legally problematic — distributing recompiled classes means distributing proprietary code, which is why Java mods remain niche. The **Storm framework** (pzstorm) attempted to solve this with a runtime class loader, but the approach never became mainstream.

---

## Kahlua in the JVM Lua landscape

**Project Zomboid is essentially the only major production game using Kahlua.** Kristofer Karlsson used it in a hobby game called "Spaced," and it powered some J2ME mobile games, but PZ is the sole high-profile user. The broader JVM Lua landscape includes **LuaJ** (faster than Kahlua due to optional Lua→Java bytecode compilation via BCEL; supports Lua 5.2; used by Minecraft mods like Figura and ComputerCraft), **JNLua** (JNI bridge to native C Lua; used by Terasology), and **Rembulan** (clean-room Lua 5.3 compiling to Java bytecode; experimental).

Kahlua's key advantage over alternatives is its **annotation-driven Java exposure system** (`@LuaMethod`, `LuaJavaClassExposer`) which PZ's entire modding API is built upon. Its key disadvantage is performance — as a pure bytecode interpreter with no JIT compilation path, it is the slowest of the pure-Java options. LuaJ's `luajc` compiler can outperform even native C Lua in some benchmarks. PZ likely adopted Kahlua early in development (~2011) when Kahlua2's Java integration features were the most mature option, and the codebase is now too deeply integrated to justify migration.

---

## Iterating Java collections from Lua (S88 working note)

Java collections (`ArrayList`, `HashMap`, etc.) reach Lua as plain `userdata`. They are NOT KahluaTables and Lua's standard `pairs` / `ipairs` will not iterate them. Instead, use the Java API directly through method dispatch:

```lua
-- Java ArrayList<E> exposed via Kahlua
local list = someApiCall()        -- returns ArrayList<IsoObject>
local n = list:size()              -- 0-indexed length
for i = 0, n - 1 do                -- Java ArrayList is 0-indexed
    local entry = list:get(i)
    -- ...
end
```

**Detection idiom** (used in `ContextMenuRegistry.lua` to discriminate inventory-RMB Lua tables from world-RMB ArrayLists):

```lua
local function isJavaList(v)
    return type(v) == "userdata" and v.size ~= nil and v.get ~= nil
end
```

This sidesteps the need for `instanceof` reflection (which would require resolving the Java class from Lua) and works across PZ versions that may swap concrete `List` implementations.

**Why this matters for the context menu:** S88 needed to distinguish whether a target was an inventory item selection (Lua table from `ISInventoryPaneContextMenu.createMenu(player, isInInv, items, x, y)`) or a world object set (Java `ArrayList<IsoObject>` from `ISWorldObjectContextMenu.createMenu(player, worldobjects, x, y)`). The unwrap logic only worked on the Lua-table case, falling through to a generic "Item" placeholder for world RMBs. Using `isJavaList` to branch on shape gave us the right display path for each.

---

## S115 Findings — Bridge Behavior Edge Cases

Three discoveries from the radio drawer implementation that sharpen the bridge's behavioral model.

### 1. `pcall` does NOT silence the engine error logger

The intuition from standard Lua — that `pcall` catches errors silently — does NOT hold under PZ's Kahlua. When a `KahluaUtil.fail` fires inside a `pcall`'d block (e.g., calling a nil method on an exposed object), Kahlua's `pcall` returns `false, errMsg` to the caller as expected, BUT the engine's error logger ALSO catches the same exception via the `LuaCaller.pcallvoid` integration path and dumps a stack trace to `console.txt`.

**Implication:** defensive `pcall(function() return obj:maybeMissingMethod() end)` patterns can spam thousands of stack traces per second when the method is consistently missing across many objects (e.g., a per-frame UI render probing 20 fields × 60 fps). Functionality works, but the log fills with noise and disk usage balloons.

**Fix pattern (field-probe, no pcall):** index the method as a table field FIRST. Kahlua's exposed-class metatable returns nil silently for missing keys (`obj.notExposed` evaluates to `nil` without invoking). Only call once you've confirmed the method exists:

```lua
if obj.maybeMissingMethod ~= nil then
    local v = obj:maybeMissingMethod()
    -- handle v
end
```

Reserve `pcall` for cases where the method exists but might throw (e.g., `ArrayList:get(N)` for N out of range — see point 2). Cross-reference: PZAPI-KB Q119.

### 2. Java `IndexOutOfBoundsException` propagates through the bridge as a stack trace

`java.util.ArrayList:get(int)` throws `IndexOutOfBoundsException` when `index >= size()`. Kahlua's bridge serializes this as a Lua-level error, which:
1. Returns `false, errMsg` from any wrapping `pcall` (correct Lua semantics).
2. ALSO logs a full stack trace to console (per point 1 above).

**Implication:** any Lua loop that iterates `for i = 1, MAX do list:get(i-1) end` without bounds-checking `MAX <= list:size()` will spam IndexOutOfBoundsException traces every frame the list is shorter than `MAX`. Encountered in S115's preset bank (slot 8 buttons rendered, but 0 entries stored).

**Fix:** check `list:size()` once before any indexed access. Kahlua's `:size()` is a cheap method call (Java field read through reflection cache). Bound the loop accordingly:

```lua
local n = (list and list.size and list:size()) or 0
for i = 1, math.min(visible, n) do
    local entry = list:get(i - 1)
    -- ...
end
```

Cross-reference: PZAPI-KB Q120.

### 3. Mutate-in-place is necessary for Lua-side static tables that get aliased

A subtle reload-time gotcha that lives entirely in Lua (no Java involvement, but worth recording here since it interacts with PZ's `/lua reload` lifecycle).

When a top-level Lua module file declares `ZeD.X = { ... }` (table literal) and another file later captures `T.x = ZeD.X` as an alias, a `/lua reload` of the first file replaces `ZeD.X` with a brand-new table. The captured alias `T.x` still points at the OLD table — its values are stale until the consumer file ALSO reloads (which happens via `applyTheme()` in the ZeD theme system, but doesn't auto-fire on every reload).

**Pattern that survives reload:**

```lua
-- Tokens.lua — mutate in place, preserve table identity across reload
ZeD.X = ZeD.X or {}
ZeD.X.field1 = "value1"
ZeD.X.field2 = "value2"
-- Reload rewrites field1/field2 in the SAME table; T.x still points at it.
```

This complements PZAPI-KB Q122. **Bridge implication:** reflective metatables on Java-exposed objects don't suffer this problem — they're recreated by the Exposer on each Lua reset, and consumers always re-fetch via `:getX()` calls. But pure-Lua static tables (Tokens, Spacing, Ctx, Gp namespaces) DO need explicit identity preservation when aliased into theme-applied palettes.

---

## Conclusion

PZ's architecture is best understood as three interlocking layers: a **Java engine** providing the game object model (150+ packages under `zombie.*`), a **Kahlua2 bridge** that creates reflection-backed metatables mirroring Java's class hierarchy, and a **Lua surface** where modders interact with game objects through method calls that transparently invoke Java reflection. Build 42's ECS adds a fourth dimension — data-driven composition via `GameEntity` components — that coexists with the existing inheritance tree. The `CompLua` component package specifically targets Lua modders, signaling that TIS intends ECS to become the primary modding interface. For an AI reading PZ code, the critical insight is that **every Lua method call is a Java method call**: the Lua API surface is a direct projection of the Java public method surface, filtered through the Exposer whitelist, with no field access and no type coercion beyond numeric conversion.