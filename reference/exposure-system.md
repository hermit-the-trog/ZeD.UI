# Exposure System — How Java Becomes Lua-Callable

## Table of Contents
1. LuaJavaClassExposer Architecture
2. LuaJavaInvoker and Method Resolution
3. MultiLuaJavaInvoker (Overload Handling)
4. Annotations (@LuaMethod, @LuaConstructor)
5. LuaBackendClass Pattern
6. The Whitelist Gatekeeper
7. Global Functions via LuaManager.GlobalObject
8. Common Traps and Edge Cases

---

## 1. LuaJavaClassExposer Architecture

`se.krka.kahlua.integration.expose.LuaJavaClassExposer` is the engine that creates Lua-accessible metatables from Java classes.

### Core Data Structures

```java
class LuaJavaClassExposer {
    // Class → metatable mapping (the central registry)
    Map<Class<?>, KahluaTable> classMetatables;

    // Class → index table (methods live here)
    Map<Class<?>, KahluaTable> classIndexTables;

    // The Lua environment
    KahluaTable env;

    // Platform for creating tables
    Platform platform;
}
```

### Exposure Flow

`exposeLikeJava(Class<?> clazz, KahluaTable environment)`:

1. **Check if already exposed** — `classMetatables.containsKey(clazz)` → skip if yes
2. **Expose parent first** — recursive call for superclass (ensures inheritance chain exists)
3. **Create metatable and index table** — two new `KahluaTable` instances
4. **Walk all public methods** — `clazz.getMethods()` returns inherited methods too
5. **For each method:**
   - Create `LuaJavaInvoker` wrapping the `Method`
   - If method name already exists in indexTable, wrap both in `MultiLuaJavaInvoker`
   - Store in indexTable: `indexTable.rawset(methodName, invoker)`
6. **Wire metatable:**
   - `metatable.rawset("__index", indexTable)`
   - Set indexTable's metatable to parent class's metatable (inheritance chain)
7. **Register:** `classMetatables.put(clazz, metatable)`

### The Metatable Chain

For `IsoPlayer extends IsoLivingCharacter extends IsoGameCharacter extends IsoMovingObject extends IsoObject extends GameEntity`:

```
IsoPlayer metatable
  __index → IsoPlayer indexTable (IsoPlayer-specific methods)
    metatable → IsoLivingCharacter metatable
      __index → IsoLivingCharacter indexTable
        metatable → IsoGameCharacter metatable
          __index → IsoGameCharacter indexTable
            metatable → IsoMovingObject metatable
              __index → IsoMovingObject indexTable
                metatable → IsoObject metatable
                  __index → IsoObject indexTable
                    metatable → GameEntity metatable
```

This is how `player:getSquare()` works even though `getSquare()` is defined on `IsoObject`, not `IsoPlayer`. The `__index` chain walks up until it finds the method.

---

## 2. LuaJavaInvoker and Method Resolution

`LuaJavaInvoker` wraps a single `java.lang.reflect.Method`:

```java
class LuaJavaInvoker implements JavaFunction {
    Method method;          // The reflected method
    Class<?>[] paramTypes;  // Parameter types
    boolean needsSelf;      // Instance method vs static
    String name;            // Lua-visible name

    int call(LuaCallFrame callFrame, int nArguments) {
        // 1. Extract self object (if instance method)
        Object self = needsSelf ? callFrame.get(0) : null;

        // 2. Extract and convert arguments
        Object[] args = new Object[paramTypes.length];
        for (int i = 0; i < paramTypes.length; i++) {
            Object luaArg = callFrame.get(needsSelf ? i+1 : i);
            args[i] = converterManager.fromLuaToJava(luaArg, paramTypes[i]);
        }

        // 3. Invoke via reflection
        Object result = method.invoke(self, args);

        // 4. Convert and push return value
        if (method.getReturnType() != void.class) {
            Object luaResult = converterManager.fromJavaToLua(result);
            callFrame.push(luaResult);
            return 1;
        }
        return 0;
    }
}
```

### Type Conversion at Call Boundaries

Inbound (Lua → Java):
- `Double` → `int/long/float/short/byte` (narrowing cast)
- `String` → enum value (by name)
- `KahluaTable` → `Map` or `List` (if converter registered)
- Java objects pass through unchanged

Outbound (Java → Lua):
- `int/long/float/short/byte` → `Double`
- `boolean` → `Boolean`
- `String` → `String` (already compatible)
- Any other object → passes through as userdata
- `null` → `nil`
- `void` → nothing pushed

---

## 3. MultiLuaJavaInvoker (Overload Handling)

When a Java class has overloaded methods (same name, different parameters), Kahlua2 wraps them in `MultiLuaJavaInvoker`:

```java
class MultiLuaJavaInvoker implements JavaFunction {
    List<LuaJavaInvoker> invokers; // Sorted by parameter count

    int call(LuaCallFrame callFrame, int nArguments) {
        // Find best match by argument count
        for (LuaJavaInvoker invoker : invokers) {
            if (invoker.paramTypes.length == effectiveArgCount) {
                return invoker.call(callFrame, nArguments);
            }
        }
        // Fallback: try closest match
        // ... error if nothing works
    }
}
```

This is parameter-count-based dispatch, not type-based. If two Java methods have the same name and same number of parameters but different types, Kahlua2 may call the wrong one. In practice this rarely happens in PZ's API because TIS avoids this pattern.

---

## 4. Annotations

### @LuaMethod

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface LuaMethod {
    String name() default "";   // Override Lua name (default: Java method name)
    boolean global() default false; // Expose as global function
}
```

When `global = true`, the method is added directly to the Lua environment table, callable without a receiver. PZ uses this sparingly — most globals come from `LuaManager.GlobalObject` instead.

### @LuaConstructor

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.CONSTRUCTOR)
public @interface LuaConstructor {
    String name() default ""; // Global function name for construction
}
```

PZ rarely uses this. Most object construction goes through factory methods (`InventoryItemFactory.CreateItem()`) exposed as global functions.

---

## 5. LuaBackendClass Pattern

PZ introduces `LuaBackendClass` — a class that implements `KahluaTable`, allowing an object to be both a Java object AND a Lua table simultaneously.

This means:
- `type(obj)` returns `"table"` (not `"userdata"`)
- `obj.key` can access both Java methods (via metatable) and arbitrary Lua-side key/value pairs (via table storage)
- `rawset(obj, key, value)` stores data on the object directly

This is used for certain PZ objects that need to carry mod-authored data alongside their Java state. The `IsoObject.table` field (a `KahluaTable` for mod data) is a different approach to the same problem — `LuaBackendClass` merges the two into one object.

---

## 6. The Whitelist Gatekeeper

`LuaManager.Exposer` overrides `shouldExpose(Class<?>)`:

```java
boolean shouldExpose(Class<?> clazz) {
    // Returns true only for approved classes
    // This is a hardcoded whitelist maintained by TIS
}
```

If a class isn't whitelisted:
- Its methods don't appear in Lua
- Instances passed to Lua still work as userdata but have no callable methods
- `type(obj)` returns `"userdata"` with no metatable

The whitelist is the reason some Java API methods you find in decompiled source don't work from Lua — the class or a parent class isn't exposed.

### How to Check What's Exposed

From Lua, you can probe:
```lua
local mt = getmetatable(someObject)
-- mt.__index contains callable methods
-- If mt is nil, the class isn't exposed
```

From Java (decompiled source), look for the class in `LuaManager.Exposer.exposeAll()` — that's where the exposure calls live.

---

## 7. Global Functions via LuaManager.GlobalObject

`LuaManager.GlobalObject` is a static inner class whose public methods become global Lua functions via `exposer.exposeGlobalFunctions(GlobalObject.class)`.

Key globals:

| Lua global | Java method | Returns |
|---|---|---|
| `getPlayer()` | `GlobalObject.getPlayer()` | `IsoPlayer` |
| `getWorld()` | `GlobalObject.getWorld()` | `IsoWorld` |
| `getGameTime()` | `GlobalObject.getGameTime()` | `GameTime` |
| `instanceItem(type)` | `GlobalObject.instanceItem(String)` | `InventoryItem` |
| `getSpecificPlayer(n)` | `GlobalObject.getSpecificPlayer(int)` | `IsoPlayer` |
| `sendClientCommand(...)` | `GlobalObject.sendClientCommand(...)` | void |
| `isClient()` | `GlobalObject.isClient()` | Boolean |
| `isServer()` | `GlobalObject.isServer()` | Boolean |
| `getTexture(path)` | `GlobalObject.getTexture(String)` | `Texture` |
| `getText(key)` | `GlobalObject.getText(String)` | `String` |

There are hundreds more. The full list is in the decompiled `LuaManager.GlobalObject` source.

---

## 8. Common Traps and Edge Cases

### Trap: Assuming Field Access Works
Java: `public int health = 100;`
Lua: `player.health` → `nil` (NOT 100)
Fix: There must be a `getHealth()` method exposed.

### Trap: Method Name Collisions with Lua Keywords
If a Java method is named `end`, `return`, `function`, etc., it can't be called naturally from Lua. Kahlua doesn't rename these — they're simply inaccessible unless the `@LuaMethod(name="...")` annotation provides an alias.

### Trap: Overloaded Methods with Same Param Count
Two Java methods: `foo(int x)` and `foo(String x)` — `MultiLuaJavaInvoker` dispatches by count, may call the wrong one. PZ generally avoids this but it exists in some corners.

### Trap: Null Returns
Java returns `null` → Lua gets `nil`. But if you're expecting a table or object and get nil, it might mean:
1. The getter genuinely returned null (object doesn't exist)
2. The method isn't exposed (class not whitelisted) — returns nil via failed __index lookup
These are indistinguishable from Lua. Check the class exposure if nil doesn't make sense.

### Trap: Threading
PZ runs Lua on multiple threads (main thread, loading thread, etc.). Kahlua2's `ConcurrentHashMap`-backed tables make table operations thread-safe, but Java object state accessed via reflection is NOT synchronized by Kahlua. PZ handles synchronization on the Java side — modders should avoid assuming thread safety for Java object state.

### Build 42 Addition: Field Overwrite Warnings
Build 42 added warnings when the Exposer detects that a method name in the indexTable would be overwritten by a field with the same name. This was a debugging aid for TIS — it surfaces as console warnings like `"Warning: method 'X' on class 'Y' was overwritten by field"`.
