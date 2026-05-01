# Java Modding Patterns for Project Zomboid

## Table of Contents
1. Legal Landscape
2. Development Setup
3. Writing Java Code for PZ
4. Exposing New Classes to Lua
5. Java-Side Event Integration
6. Common Patterns
7. Debugging Java-Side Issues from Lua

---

## 1. Legal Landscape

Java modding in PZ occupies a legal gray area. The core issue: distributing modified `.class` files means distributing TIS's proprietary code. This is why Java mods are rare on the Workshop compared to Lua mods.

**What's clearly OK:**
- Reading decompiled source for understanding (personal use)
- Writing Lua mods that call exposed Java methods
- Using Java knowledge to write better Lua mods

**What's gray:**
- Distributing recompiled Java classes (most Workshop rules prohibit this)
- Runtime class loading/patching (technically possible but unsupported)

**What's clearly not OK:**
- Redistributing the full decompiled source
- Bypassing the Exposer whitelist to access restricted classes

For ZeD-UI and most modding purposes, the Java layer is **read-only intelligence** — you study it to understand what's possible from Lua, not to ship modified Java.

---

## 2. Development Setup

### Decompiling PZ

**Recommended: Zomboid Decompiler (Vineflower)**
1. Download from GitHub (demiurgeQuantified)
2. Requires Java 17+
3. Auto-detects Steam install path
4. Produces clean `.java` files with JavaDoc-informed variable names
5. Supports debug line remapping for remote debugging

**Alternative: Capsid (Gradle)**
```bash
# In a Capsid project:
gradle decompileZomboid    # Decompile all JARs
gradle annotateZomboid     # Add type annotations
gradle compileZomboid      # Compile against PZ classes
```

### Setting Up a Compile-Against Environment

If you need to write Java that compiles against PZ's classes:

1. Decompile PZ JARs to get the class definitions
2. Add PZ's JAR files to your project's classpath
3. Target Java 17
4. Don't import internal/private classes — they may change between builds

Key JARs in PZ's install directory:
- `zombie.jar` — main game code
- `jassimp.jar`, `lwjgl*.jar`, `sqlite-jdbc*.jar` — dependencies
- Kahlua2 classes are inside `zombie.jar` under `se.krka.kahlua.*`

---

## 3. Writing Java Code for PZ

### Convention Matching

PZ's Java style:
- Heavy use of `static` methods and singletons
- Package-private access for internal state
- `public` methods = Lua-accessible (if class is exposed)
- Inner classes for related data structures
- Direct field access within the package, getters for external access
- `ArrayList` preferred over `List` interface in many places
- Null returns common — always null-check

### A Minimal Java Class for PZ

```java
package zombie.mymod;

import zombie.characters.IsoPlayer;
import zombie.Lua.LuaManager;
import se.krka.kahlua.integration.annotations.LuaMethod;

public class MyModHelper {

    // Exposed as global Lua function: MyModHelper.getPlayerStatus(player)
    @LuaMethod(global = false)
    public static String getPlayerStatus(IsoPlayer player) {
        if (player == null) return "unknown";
        float health = player.getHealth();
        if (health > 0.75f) return "healthy";
        if (health > 0.25f) return "wounded";
        return "critical";
    }

    // To expose this class to Lua:
    public static void expose() {
        LuaManager.exposer.exposeLikeJava(MyModHelper.class, LuaManager.env);
    }
}
```

---

## 4. Exposing New Classes to Lua

### Using the Exposer

```java
// Expose all public methods of a class
LuaManager.exposer.exposeLikeJava(MyClass.class, LuaManager.env);

// Expose with annotation-driven selection
LuaManager.exposer.exposeClass(MyClass.class);

// Expose global functions from static methods
LuaManager.exposer.exposeGlobalFunctions(MyClass.class);
```

### Annotation Options

```java
// Instance method — called as obj:methodName()
@LuaMethod
public String getName() { return this.name; }

// Static method exposed as global — called as globalFuncName()
@LuaMethod(global = true)
public static IsoPlayer getClosestPlayer(float x, float y) { ... }

// Renamed method — Lua sees "customName" not "internalMethodName"
@LuaMethod(name = "customName")
public void internalMethodName() { ... }
```

### What Gets Exposed Automatically

`exposeLikeJava()` exposes ALL public methods including inherited ones. The metatable chain mirrors Java inheritance. If you expose `MyClass extends IsoObject`, all `IsoObject` public methods are also callable on `MyClass` instances from Lua.

### What Doesn't Get Exposed

- Fields (no automatic property access)
- Private/protected methods
- Package-private methods
- Static fields
- Constructors (unless `@LuaConstructor` annotated)

---

## 5. Java-Side Event Integration

### Triggering Lua Events from Java

```java
import zombie.Lua.LuaEventManager;

// Fire an event that Lua can listen to
LuaEventManager.triggerEvent("OnMyCustomEvent", arg1, arg2);

// Lua side:
// Events.OnMyCustomEvent.Add(function(arg1, arg2)
//     print("Custom event fired!")
// end)
```

### Registering New Event Types

Events don't need explicit registration — just trigger them by name. Lua code calls `Events.EventName.Add(callback)` to subscribe. If no one subscribes, triggering is a no-op.

### Hooking into Existing Java Code

Without modifying Java classes directly, you can:
1. Use Lua events that Java already triggers
2. Use Lua hooks (`Hook.Add()`)
3. Override Lua functions that Java calls back into

---

## 6. Common Patterns

### Pattern: Reading Java Source to Find Lua API Methods

When you need to know what methods are available on a Java object from Lua:

1. Find the class in decompiled source (e.g., `zombie/characters/IsoPlayer.java`)
2. List all `public` methods — these are the Lua-callable methods (if class is exposed)
3. Check parent classes — inherited public methods are also available
4. Confirm the class is in the exposure whitelist (check `LuaManager.Exposer.exposeAll()`)

### Pattern: Tracing a Lua Method to Its Java Implementation

Starting from Lua: `player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)`

1. `getBodyDamage()` → `IsoGameCharacter.getBodyDamage()` → returns `BodyDamage`
2. `getBodyPart(BodyPartType.Hand_L)` → `BodyDamage.getBodyPart(BodyPartType)` → returns `BodyPart`
3. Check return type's exposed methods to see what's callable next

### Pattern: Understanding Why Something Returns Nil

Lua code returns nil when you expected a value. Possible Java-side causes:

1. **Method genuinely returns null** — check Java source for null return paths
2. **Class not exposed** — object has no metatable, all method lookups return nil
3. **Method doesn't exist by that name** — check exact method name spelling (Java is case-sensitive, and Lua preserves this)
4. **Wrong method overload selected** — `MultiLuaJavaInvoker` picked wrong overload
5. **Field access attempted** — `obj.field` doesn't work; need `obj:getField()`

### Pattern: Finding the Right Java Class for a Game Object

From Lua, determine an object's Java class:
```lua
local obj = someObject
local className = tostring(getmetatable(obj))
-- Or check type:
print(type(obj))  -- "userdata" for Java objects, "table" for Lua objects
```

From Java source, trace creation:
- Items: `InventoryItemFactory.CreateItem(type)` → check script `item` block → `Type` field determines subclass
- World objects: `IsoObject` subclass is set by sprite/tile properties
- Characters: Always `IsoPlayer`, `IsoZombie`, or `IsoAnimal`

---

## 7. Debugging Java-Side Issues from Lua

### Reading Stack Traces

PZ error logs show the full Java+Kahlua stack:

```
ERROR: General, ...
java.lang.NullPointerException
  at zombie.characters.IsoGameCharacter.getBodyDamage(IsoGameCharacter.java:4521)
  at se.krka.kahlua.integration.expose.caller.MethodCaller.call(MethodCaller.java:62)
  at se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:198)
  at se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:182)
  at se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:1007)
```

Reading this bottom-up:
1. `KahluaThread.luaMainloop` — Lua code was executing
2. `KahluaThread.callJava` — dispatched to a Java function
3. `LuaJavaInvoker.call` — the bridge invoked a reflected method
4. `MethodCaller.call` — reflection call executed
5. `IsoGameCharacter.getBodyDamage:4521` — the actual Java method, with line number

The Java line number + decompiled source = exact point of failure.

### Common Error Patterns

| Error | Java Cause | Lua Fix |
|---|---|---|
| `NullPointerException` at getter | Object state is null | nil-check before calling |
| `ClassCastException` | Wrong argument type to Java method | Check expected type in JavaDocs |
| `IndexOutOfBoundsException` | Array/list access out of range | Check size before accessing |
| `ConcurrentModificationException` | Iterating a list that's being modified | Copy list before iterating |
| `StackOverflowError` | Recursive __index chain or infinite Lua recursion | Check for circular metatable references |

### Remote Debugging

The Zomboid Decompiler supports debug line remapping, enabling remote debugging with IntelliJ IDEA:
1. Decompile with line mapping enabled
2. Attach IntelliJ debugger to PZ's JVM (launch with `-agentlib:jdwp=...`)
3. Set breakpoints in decompiled source
4. Step through Java execution triggered by Lua calls

This is the most powerful debugging tool available for understanding Java-side behavior.
